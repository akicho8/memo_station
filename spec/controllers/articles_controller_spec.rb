# -*- coding: utf-8 -*-

require "rails_helper"

RSpec.describe ArticlesController, type: :controller do
  before do
    Article.destroy_all
    @article = article_create
  end

  context "index" do
    it "index" do
      get :index
      assert_response :success
    end

    it "検索" do
      get :index, params: {:query => @article.tag_list, :format => "text"}
      assert_response :success
      assert_match /#{@article.id}.*#{@article.title}.*#{@article.tag_list}.*#{@article.body}/m, response.body
    end
  end

  it "show" do
    get :show, params: {:id => @article.id}
    assert_response :success
  end

  it "new" do
    get :new
    assert_response :success
  end

  it "create" do
    process :create, :method => :post, :params => {:article => {:title => hex, :tag_list => hex, :body => hex}}
    assert_response :redirect
  end

  it "edit" do
    get :edit, params: {:id => @article.id}
    assert_response :success
  end

  it "update" do
    process :update, :method => :put, :params => {:id => @article.id, :article => {:title => hex, :tag_list => hex, :body => hex}}
    assert_response :redirect
  end

  it "destroy" do
    process :destroy, :method => :delete, :params => {:id => @article.id}
    assert_response :redirect
  end

  it "test_post" do
    process :text_post, :method => :post, :params => {:content => "
Title: #{hex}
Tag: #{hex}
--text follows this line--
#{hex}
"}
    assert_response :success
  end
end
