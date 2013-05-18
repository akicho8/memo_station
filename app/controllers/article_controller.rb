require "csv"

module ForEmacs
  def text_get
    if params[:id]
      article = Article.find(params[:id])
      output = article.to_text
    elsif params[:query]
      queries = tags_string_to_tag_names(params[:query])
      unless queries.empty?
        articles = Article.find_tagged_with(:all => queries, :order => "articles.created_at DESC", :limit => (params[:limit] || 100).to_i)
      else
        articles = []
      end
      separator = "-" * 80 + "\n"
      output = separator + articles.map{|article|article.to_text}.join(separator) + separator
    else
      raise "パラメータが足りません。"
    end
    render_text_for_emacs(output)
  end

  def text_post
    out = ""
    if ENV["RAILS_ENV"] == "development"
      out << [request.method, request.raw_post, request.query_string, params].inspect + "\n"
    end
    out << Article.text_post(params[:content], self)
    render_text_for_emacs(out)
  end

  private
  def render_text_for_emacs(str)
    headers["Content-Type"] = "text/plain; charset=UTF-8"
    render :text => str + "-- content end --" + "\n"
  end
end

module ForRSS
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ApplicationHelper

  def rss
    require "rss/maker"
    rss = RSS::Maker.make("1.0") do |maker|
      maker.channel.about = url_for(:action => "rss")
      maker.channel.title = APPLICATION_TITLE
      maker.channel.link = url_for(:action => "index")
      maker.channel.description = "#{APPLICATION_TITLE} feeds generated by RSS::Maker"
      Article.find(:all, :order => "modified_at desc", :limit => 30).each do |article|
        item = maker.items.new_item
        item.title = article.subject
        item.date = article.modified_at
        item.link = url_for(:action => "show", :id => article)
        item.description = truncate(strip_tags(article.body).to_a.map{|e|e.strip}.join(" "), 80)
        item.content_encoded = html_escape(article_simple_format(article.body))
        item.dc_creator = article.user.loginname
      end
    end
    headers["Content-Type"] = "application/xml; charset=UTF-8"
    render :text => rss, :layout => false
  end
end

module ForExport
  def export
    if params[:type]
      @articles = Article.find(:all, :order => "id", :offset => params[:offset], :limit => params[:limit])
      download_trap_ie_browser
      send("export_#{params[:type]}")
    end
  end

  private

  # "&#10" はExcelの改行を意味する。
  # XmlMarkupを普通に使うと & がエスケープされてしまうため読めなくなる。
  # だから「&amp;#10」を「&#10」に戻す。
  # XmlMarkupの<<メソッドを使ってテンプレート側で対処する方法もあるけど、その場合、インデントを自分で調整しなければならない。
  # 恐しく面倒な上に汎用性もない。
  # なので結局はこっちで置換した方がまし。
  #
  # &#10があちこちに分散しているとわかりにくいので定数 __ARTICLE_BODY_CR_IN_EXCEL_CELL__ を使うようにした。
  def export_excel
    str = render_to_string :action => "export_excel", :layout => false
    str.gsub!(/__ARTICLE_BODY_CR_IN_EXCEL_CELL__/, "&#10")
    send_data(str, :filename => "#{download_file_basename}.xml", :type => "application/vnd.ms-excel")
  end

  def export_pdf
    file_download_mode = false
    kanji_code_environment("EUC") {
      pdf = PDF::Writer.new(:paper => "A4")
      pdf.select_font("Ryumin-Light", "EUC-H")

      @articles.each_with_index{|article, index|
        pdf.text "#{index.succ}.#{article.subject}".toeuc, :font_size => 18
        pdf.text "\n".toeuc, :font_size => 8
        pdf.text "#{article.body}".toeuc, :font_size => 12
        pdf.text "\n".toeuc, :font_size => 8
        pdf.text "(#{article.user.loginname}) - #{article.created_at.to_s(:pdf)}".toeuc, :font_size => 8
        pdf.text "\n".toeuc, :font_size => 24
      }
      send_options = {:filename => "#{download_file_basename}.pdf", :type => "application/pdf"}
      if file_download_mode
        pdf.save_as("#{download_file_basename}.pdf")
        send_file("#{download_file_basename}.pdf", send_options)
      else
        send_data(pdf.render, send_options)
      end
    }
  end

  def export_csv
    buffer = ""
    column_size = Article.find(:first).export_row.size
    Article.find(:all).each{|article|
      CSV.generate_row(article.export_row, column_size, buffer)
    }
    if true
      send_data buffer.tosjis, :type => "text/csv; charset=Shift_JIS", :filename => "#{download_file_basename}.csv"
    else
      render :text => buffer
    end
  end

  def export_mysql_csv
    mysql_csv_path = Article.export_mysql_csv
    if true
      send_file mysql_csv_path.to_s, :type => "text/csv; charset=UTF-8", :filename => "#{download_file_basename}.csv"
    else
      render :text => mysql_csv_path.read
    end
  end

  def download_file_basename
    SEARCH_PLUGIN_NAME
  end

  def kanji_code_environment(kcode)
    begin
      save_kcode, $KCODE = $KCODE, kcode
      yield
    ensure
      $KCODE = save_kcode
    end
  end
end

class ArticleController < ApplicationController
  before_filter :login_required, :only => [:new, :edit, :update, :destroy, :recent_viewed]

  include ForRSS
  include ForEmacs
  include ForExport

  def index
    list
  end

  def list
    @article_pages = Paginator.new(self, Article.count, params[:limit] || 30, params[:page])
    @articles = Article.find(:all, :order => "updated_at desc", :offset => @article_pages.current.offset, :limit => @article_pages.items_per_page)
    render :action => "list"
  end

  def bookmark
    Article.with_scope(:find => {:conditions => "url is not null"}) {
      @article_pages = Paginator.new(self, Article.count, params[:limit] || 30, params[:page])
      @articles = Article.find(:all, :order => "url_access_at desc", :offset => @article_pages.current.offset, :limit => @article_pages.items_per_page)
    }
    render :action => "list"
  end

  # 最近見たメモ
  def recent_viewed
    @article_pages = Paginator.new(self, session[:user].recent_viewed_count, params[:limit] || 30, params[:page])
    @articles = session[:user].recent_viewed(:offset => @article_pages.current.offset, :limit => @article_pages.items_per_page)
    render :action => "list"
  end

  def most_viewed
    case params[:period]
    when "today"
      @page_title = "今日"
      before_time = Time.now.beginning_of_day
    when "week"
      @page_title = "1週間でいちばん"
      before_time = 1.week.ago
    when "month"
      @page_title = "1ヶ月間でいちばん"
      before_time = 1.month.ago
    when "all"
      @page_title = "全体でいちばん"
      before_time = 1.years.ago
    else
      @page_title = "今日"
      before_time = Time.now.beginning_of_day
    end

    count = Article.most_viewed_count(before_time)
    @article_pages = Paginator.new(self, count, params[:limit] || 30, params[:page])
    @articles = Article.most_viewed(before_time, :offset => @article_pages.current.offset, :limit => @article_pages.items_per_page)

    logger.debug(@articles.map(&:created_at).inspect)

    render :action => "list"
  end

  def show
    @article = find_article
  end

  # URLをクリックした時間を更新してからジャンプする。
  #
  # HTML側でのhrefはブラウザにジャンプ先がわかるようにしているだけで
  # 実際にジャンプさせているのはこのメソッド
  #
  # としていたけど、Firefoxの場合、& が &amp; になってしまう問題がでてきた。
  # またHTML側の記述も link_to_function + remote_function を使うより link_to だけで記述した方がスマートだった。
  #
  # だからここでの処理はカラム更新のみとした。
  def url_access_remote
    article = find_article
    article.update_attribute(:url_access_at, Time.now)
    if false
      render(:update){|page|
        page.redirect_to(article.url)
      }
    else
      render :nothing => true
    end
  end

  def show_remote
    show
    render(:update){|page|
      page.replace_html "article_#{@article.id}", render(:partial => "article_content")
    }
  end

  def related_articles
    show
    render(:update){|page|
      page.replace_html "article_#{@article.id}_related_articles", render(:partial => "related_articles")
    }
  end

  def link_jump
    article = find_article
    redirect_to_url(article.url)
  end

  def destroy
    unless request.post?
      flash[:notice] = "無効なアクセスです。"
      redirect_to :action => "list"
      return
    end
    Article.find(params[:id]).destroy
    flash[:notice] = "削除しました。"
    redirect_to :action => "list"
  end

  def new
    @article = Article.new
    [:subject, :body, :url].each do |name|
      @article[name] = params[name].to_s.strip
    end
    render :action => :edit
  end

  def edit
    @article = Article.find(params[:id])
  end

  # save と deliver_article_update を transaction に入れておくとメールで失敗したときは保存されない。
  def update
    if params[:id].blank?
      @article = Article.new
      status = "投稿"
    else
      status = "更新"
      @article = Article.find(params[:id])
    end
    @before_article = @article.dup
    @article.attributes = params[:article]
    @article.user ||= session[:user]
    Article.transaction {
      unless @article.save
        render :action => "edit"
        return
      end
    }
    Mailman.deliver_article_update(self, Time.now, :article => {:before => @before_article, :after => @article})
    flash[:notice] = "#{status}しました。"
    flash[:notice_duration] = 0.8
    redirect_to :action => "list"
  end

  before_filter(:only => [:search, :search_remote]) {|controller|
    controller.instance_eval{
      count = 0
      @articles = []
      @query = params[:query]

      @queries = tags_string_to_tag_names(@query)
      unless @queries.empty?
        count = Article.count_uniq_tagged_with(:all => @queries)
      end
      @article_pages = Paginator.new(self, count, 20, params[:page])
      unless @queries.empty?
        @articles += Article.find_tagged_with(:all => @queries, :order => "updated_at DESC", :limit => @article_pages.items_per_page, :offset => @article_pages.current.offset)
      end
    }
  }

  def search
    render :action => "list"
  end

  def search_remote
    render :partial => action_name
  end

  def sidebar_tag_cloud
    @tagged_items = Article.tags_count(:count => ">= 1", :limit => 50)
    render :partial => action_name
  end

  # 人気メモ
  def sidebar_most_viewed_articles
    @articles = Article.most_viewed(1.years.ago, :offset => 0, :limit => 10)
    render :partial => action_name
  end

  # 最近登録したメモ
  def sidebar_latest_articles
    @articles = Article.find(:all, :order => "created_at DESC", :limit => 10)
    render :partial => action_name
  end

  def graph
  end

  # 検索プラグインを登録するための定義ファイルを動的生成
  # 静的ファイルにアクセスしているように見せて実際は routes.rb によりここが呼ばれる。
  #
  # 問題点
  #   .src のせいかよくわからないけど文字コードが EUC で吐かれてしまう。
  #   .UNIXでもWindowsでも Shift_JIS で書かないといけない。
  #
  # 対処
  #
  # skip_after_filter :fire_flash
  def search_plugin_source
    render :layout => false
    headers["Content-Type"] = "text/plain; charset=Shift_JIS"
    response.body = response.body.tosjis
  end

  # アクション実行直後にSJIS変換して他のフィルタをカットする方法もある。
  # でも他のフィルタはないためアクション内で完結させるようにした。
  if false
    prepend_after_filter(:only => :search_plugin_source){|c|
      logger.debug("run prepend_after_filter: search_plugin_source")
      c.headers["Content-Type"] = "text/plain; charset=Shift_JIS"
      c.response.body = c.response.body.tosjis
      false
    }
  end

  def tag_list_input_remote
    keywords = []
    @tag_names = tags_string_to_tag_names(params[:tag_list])
    @select_tags_rows = @tag_names.map{|tag_name|
      {
        :tag_name => tag_name,
        :related_tags => Article.find_related_tags(tag_name),
      }
    }
    render(:update){|page|
      page.replace_html "article_tag_choice", render(:partial => "article_tag_choice")
      page[:article_tag_choice].show # 「非表示ボタン」が押されたときはこれで表示に戻す
    }
  end

  # タグのトグルをRuby側で行な場合の処理
  # JavaScriptだけを使う場合は不要
  # メリットは tags_string_to_tag_names などの便利メソッドを共有できる。
  # デメリットは若干反応が鈍くなる。
  def tag_toggle_remote
    @tag_names = tags_string_to_tag_names(params[:tag_list])
    @tag_name = params[:tag_name]
    if find = @tag_names.tag_find(@tag_name)
      @tag_names.delete(find)
    else
      @tag_names << @tag_name
    end
    @tags_string = (@tag_names.join(" ") + " ").lstrip
    render(:update){|page|
      page << "$('article_tag_list').value = '#{@tags_string}';"
      page[:article_tag_list].focus
    }
  end

  def subject_input_remote
    render(:update){|page|
      page.replace_html :article_subject_warn, Article.find_by_subject(params[:subject].ja_strip, :conditions => ["id != ?", params[:id].to_i]) ? "(同じ題名のメモがあります)" : ""
    }
  end

  private

  def download_trap_ie_browser
    if request.env['HTTP_USER_AGENT'].match(/msie/i)
      headers['Pragma'] = ''
      headers['Cache-Control'] = ''
    else
      headers['Pragma'] = 'no-cache'
      headers['Cache-Control'] = 'no-cache, must-revalidate'
    end
  end

  # 検索などでタグをずらずら入力した一塊の文字列を、個々のタグに分割した配列を返す
  def tags_string_to_tag_names(tags_string)
    tags_string.to_s.split(TAG_SEPARATOR).find_all{|tag|!tag.empty?}
  end

  # development 環境のときだけ自分で自分のカルマを上げられるのでリロードする。
  # リロードしないとカルマがセッションに反映されない。
  def find_article
    article = Article.find(params[:id])
    article.update_attribute(:access_date, Time.now)
    raise unless session
    session[:view_articles] ||= {}
    time = session[:view_articles][article.id]
    if time
      next_time = 1.day.since(time)
    end
    if time.nil? || Time.now > next_time
      session[:view_articles][article.id] = Time.now
      Article.increment_counter(:access_count, params[:id])
      if session[:user]
        if article.user.id != session[:user].id || ENV["RAILS_ENV"] == "development"
          article.user.user_info.karma += 1
          article.user.user_info.save!
          if session[:user].id == article.user.id
            session[:user].reload
          end
        end
      end
    end
    if false
      if ENV["RAILS_ENV"] == "development"
        flash[:notice] = "now=#{Time.now} next_time=#{next_time} #{session[:view_articles].inspect}"
      end
    end
    if true
      article_view_log = article.article_view_logs.build
      article_view_log.user = session[:user]
      article_view_log.save!
    end
    article
  end
end
