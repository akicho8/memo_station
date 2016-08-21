# 独自のパーサー定義
class SoftParser < ActsAsTaggableOn::GenericParser
  def parse
    s = @tag_list
    if s.respond_to?(:join)
      s = s.join(" ")
    end
    s = s.to_s.gsub(delimiter, " ").squish
    list = s.split(delimiter).uniq
    ActsAsTaggableOn::TagList[*list]
  end

  def delimiter
    /[[:space:],|]/
  end
end
