# -*- coding: utf-8 -*-

class ArticlesController < ApplicationController
  before_filter :load_object

  # GET /articles
  # GET /articles.xml
  def index
    if params.has_key?(:query)
      @articles = Article.tagged_with(params[:query]).limit(params[:limit] || 100)
    else
      @articles = Article.limit(params[:limit] || 100)
    end

    respond_to do |format|
      format.html
      format.xml { render :xml => @articles }
      format.txt { render_text_for_emacs(Article.collection_to_txt(@articles)) }
    end
  end

  def text_post
    out = ""
    if Rails.env.development?
      out << [request.method, request.raw_post, request.query_string, params].inspect + "\n"
    end
    out << Article.text_post(params[:content])
    render_text_for_emacs(out)
  end

  def render_text_for_emacs(str)
    # headers["Content-Type"] = "text/plain; charset=UTF-8"
    render :text => str + "-- content end --" + "\n"
    # render :txt => @articles
  end

  # GET /articles/1
  # GET /articles/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/new
  # GET /articles/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @article }
    end
  end

  # GET /articles/1/edit
  def edit
  end

  # POST /articles
  # POST /articles.xml
  def create
    @article.assign_attributes(params[:article], :without_protection => true)

    respond_to do |format|
      if @article.save
        format.html { redirect_to(@article, :notice => 'Article was successfully created.') }
        format.xml  { render :xml => @article, :status => :created, :location => @article }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /articles/1
  # PUT /articles/1.xml
  def update
    @article = Article.find(params[:id])

    respond_to do |format|
      if @article.update_attributes(params[:article])
        format.html { redirect_to(@article, :notice => 'Article was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @article.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.xml
  def destroy
    @article.destroy

    respond_to do |format|
      format.html { redirect_to(articles_url) }
      format.xml  { head :ok }
    end
  end

  def load_object
    if params[:id]
      @article = Article.find(params[:id])
    else
      @article = Article.new
    end
  end
end