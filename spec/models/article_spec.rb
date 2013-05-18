# -*- coding: utf-8 -*-

require "spec_helper"

describe Article do
  context "作成系" do
    it "作成できる" do
      subject.update_attributes(:title => "title", :body => "body", :tag_list => "a b c")
      subject.should be_valid
    end
    it "タグが設定されてないので作成できない" do
      subject.update_attributes(:title => "title", :body => "body", :tag_list => "")
      subject.should be_invalid
    end
    # it "%が含まれているので作成できない" do
    #   subject.update_attributes(:title => "title", :body => "body", :tag_list => "%")
    #   subject.should be_invalid
    # end
    # it "タグに変な文字が入っているので作成できない" do
    #   "%{}#^$".scan(/./).each do |char|
    #     subject.update_attributes(:title => "title", :body => "body", :tag_list => char)
    #     subject.should be_invalid
    #     subject.should have(1).errors_on(:tag_list)
    #   end
    # end
    it "シングルクォートやダブルクォートで囲めばスペースが含まれていてもOKでtag_listを文字列で参照するとき復元してくれる" do
      subject.update_attributes(:title => "title", :body => "body", :tag_list => "'a b' c")
      subject.should be_valid
      subject.tag_list.should == ["a b", "c"]
      subject.tag_list.to_s.should == "\"a b\" c"
    end
  end

  context "更新系" do
    subject{FactoryGirl.create(:article)}
    it "更新できる" do
      subject.update_attributes(:tag_list => "a b c")
      subject.should be_valid
    end
    it "タグが消えたので更新できない" do
      subject.update_attributes(:tag_list => "")
      subject.should be_invalid
    end
    it "タイトルだけを書き換えれる" do
      subject.update_attributes(:title => "title2")
      subject.should be_valid
    end
    it "タイトルを空にすることはできない" do
      subject.update_attributes(:title => "")
      subject.should be_invalid
    end
    it "本文を空で更新することはできる" do
      subject.update_attributes(:body => "")
      subject.should be_valid
    end
  end

  context "削除系" do
    subject{FactoryGirl.create(:article)}
    before{subject}
    it "削除できる" do
      lambda{subject.destroy}.should change(Article, :count).by(-1)
    end
  end
end
