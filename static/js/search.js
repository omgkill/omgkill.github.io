summaryInclude = 30;
var currentFilter = "all";

// 确保浏览器返回时回到首页
(function() {
  var homeUrl = window.location.origin + "/";
  if (document.referrer && document.referrer.indexOf(window.location.origin) === -1) {
    // 从外部进入，替换历史记录
    history.replaceState(null, "", window.location.href);
    history.pushState(null, "", window.location.href);
    window.onpopstate = function() {
      window.location.href = homeUrl;
    };
  } else if (!document.referrer || document.referrer === window.location.href) {
    // 直接访问搜索页面
    history.replaceState(null, "", window.location.href);
    history.pushState(null, "", window.location.href);
    window.onpopstate = function() {
      window.location.href = homeUrl;
    };
  }
})();

var fuseOptions = {
  shouldSort: true,
  includeMatches: true,
  threshold: 0.3,
  tokenize: false,
  location: 0,
  distance: 100000,
  maxPatternLength: 32,
  minMatchCharLength: 1,
  keys: [
    { name: "title", weight: 0.8 },
    { name: "contents", weight: 0.5 },
    { name: "tags", weight: 0.3 },
    { name: "categories", weight: 0.3 }
  ]
};

var searchQuery = param("s");
if (searchQuery) {
  $("#search-query").val(searchQuery);
  executeSearch(searchQuery);
} else {
  $("#search-results").append('<div class="search-hint">输入关键词开始搜索</div>');
}

// 筛选按钮点击事件
$(document).on("click", ".filter-btn", function () {
  $(".filter-btn").removeClass("active");
  $(this).addClass("active");
  currentFilter = $(this).data("filter");
  
  var query = $("#search-query").val();
  if (query) {
    executeSearch(query);
  }
});

function executeSearch(searchQuery) {
  $.getJSON("/index.json", function (data) {
    var pages = data;
    var fuse = new Fuse(pages, fuseOptions);
    var result = fuse.search(searchQuery);
    console.log({ matches: result });

    // 根据 permalink 去重
    var seen = {};
    result = result.filter(function (item) {
      var permalink = item.item.permalink;
      if (seen[permalink]) {
        return false;
      }
      seen[permalink] = true;
      return true;
    });

    // 根据筛选条件过滤结果
    if (currentFilter !== "all") {
      result = result.filter(function (item) {
        var hasMatch = false;
        $.each(item.matches, function (idx, match) {
          if (currentFilter === "title" && match.key === "title") {
            hasMatch = true;
          } else if (currentFilter === "content" && match.key === "contents") {
            hasMatch = true;
          }
        });
        // 如果是内容筛选，也检查内容中是否包含搜索词
        if (currentFilter === "content" && !hasMatch) {
          hasMatch = item.item.contents.toLowerCase().indexOf(searchQuery.toLowerCase()) !== -1;
        }
        return hasMatch;
      });
    }

    // 按日期从大到小排序（最新的在前面）
    result.sort(function (a, b) {
      var dateA = a.item.date || 0;
      var dateB = b.item.date || 0;
      return dateB - dateA;
    });

    if (result.length > 0) {
      populateResults(result, searchQuery);
    } else {
      $("#search-results").html('<div class="no-results"><div class="no-results-icon">🔍</div><div class="no-results-text">未找到相关结果</div></div>');
    }
  });
}

function populateResults(result, searchQuery) {
  // 显示搜索统计
  $("#search-results").html('<div class="search-stats">找到 ' + result.length + ' 篇相关文章</div>');

  $.each(result, function (key, value) {
    var contents = value.item.contents;
    var snippet = "";
    var snippetHighlights = [];
    var hasTitleMatch = false;
    var hasContentMatch = false;
    var hasTagMatch = false;
    var hasCategoryMatch = false;

    // 分析匹配类型
    $.each(value.matches, function (matchKey, mvalue) {
      if (mvalue.key === "title") {
        hasTitleMatch = true;
        snippetHighlights.push(mvalue.value);
      } else if (mvalue.key === "tags") {
        hasTagMatch = true;
        snippetHighlights.push(mvalue.value);
      } else if (mvalue.key === "categories") {
        hasCategoryMatch = true;
        snippetHighlights.push(mvalue.value);
      } else if (mvalue.key === "contents") {
        hasContentMatch = true;
        // 直接在内容中查找搜索词的位置
        var lowerContents = contents.toLowerCase();
        var lowerQuery = searchQuery.toLowerCase();
        var matchPos = lowerContents.indexOf(lowerQuery);
        
        if (matchPos !== -1) {
          var matchStart = matchPos;
          var matchEnd = matchPos + searchQuery.length;

          // 尝试提取完整的句子
          var sentenceStart = findSentenceStart(contents, matchStart);
          var sentenceEnd = findSentenceEnd(contents, matchEnd);

          var start = Math.max(0, Math.min(sentenceStart, matchStart - summaryInclude));
          var end = Math.min(contents.length, Math.max(sentenceEnd, matchEnd + summaryInclude));

          if (snippet.length > 0) {
            snippet += " ... ";
          }
          snippet += contents.substring(start, end);
          snippetHighlights.push(contents.substring(matchStart, matchEnd));
        }
      }
    });

    // 如果没有内容匹配，但在内容中搜索到了关键词，则显示包含关键词的句子
    if (!hasContentMatch && contents.toLowerCase().indexOf(searchQuery.toLowerCase()) !== -1) {
      var matchPos = contents.toLowerCase().indexOf(searchQuery.toLowerCase());
      var sentenceStart = findSentenceStart(contents, matchPos);
      var sentenceEnd = findSentenceEnd(contents, matchPos + searchQuery.length);

      var start = Math.max(sentenceStart, matchPos - summaryInclude);
      var end = Math.min(sentenceEnd, matchPos + searchQuery.length + summaryInclude);

      snippet += contents.substring(start, end);
      hasContentMatch = true;
    }

    // 如果没有内容匹配但有标题/标签/分类匹配，显示文章开头作为摘要
    if (snippet.length < 1) {
      snippet += contents.substring(0, summaryInclude * 2);
      if (contents.length > summaryInclude * 2) {
        snippet += "...";
      }
    }

    // 格式化日期
    var dateStr = "";
    if (value.item.date) {
      var date = new Date(value.item.date * 1000);
      dateStr = date.toLocaleDateString();
    }

    // 构建匹配类型标签
    var matchTypes = [];
    if (hasTitleMatch) matchTypes.push("标题");
    if (hasContentMatch) matchTypes.push("内容");
    if (hasTagMatch) matchTypes.push("标签");
    if (hasCategoryMatch) matchTypes.push("分类");

    // 从模板获取并渲染
    var templateDefinition = $("#search-result-template").html();
    var output = render(templateDefinition, {
      key: key,
      title: value.item.title,
      link: value.item.permalink,
      tags: value.item.tags ? value.item.tags.join(", ") : "",
      categories: value.item.categories ? value.item.categories.join(", ") : "",
      snippet: snippet,
      date: dateStr,
      matchTypes: matchTypes.join("、")
    });

    $("#search-results").append(output);

    // 高亮匹配文本
    $.each(snippetHighlights, function (snipkey, snipvalue) {
      if (snipvalue) {
        $("#summary-" + key).mark(snipvalue);
      }
    });

    // 如果内容中包含搜索词但没有被 Fuse.js 标记，手动高亮
    if (hasContentMatch && snippet.toLowerCase().indexOf(searchQuery.toLowerCase()) !== -1) {
      $("#summary-" + key).mark(searchQuery, {
        separateWordSearch: false,
        caseSensitive: false
      });
    }
  });
}

// 查找句子开始位置
function findSentenceStart(text, position) {
  var start = position;
  var sentenceEnders = ['。', '！', '？', '！', '?', '.', '!', '\n'];

  // 向前查找句子结束符
  while (start > 0) {
    var char = text[start - 1];
    if (sentenceEnders.indexOf(char) !== -1) {
      start++;
      break;
    }
    start--;
  }

  return start;
}

// 查找句子结束位置
function findSentenceEnd(text, position) {
  var end = position;
  var sentenceEnders = ['。', '！', '？', '！', '?', '.', '!', '\n'];

  // 向后查找句子结束符
  while (end < text.length) {
    var char = text[end];
    if (sentenceEnders.indexOf(char) !== -1) {
      end++;
      break;
    }
    end++;
  }

  return end;
}

function param(name) {
  return decodeURIComponent(
    (location.search.split(name + "=")[1] || "").split("&")[0]
  ).replace(/\+/g, " ");
}

function render(templateString, data) {
  var conditionalMatches, conditionalPattern, copy;
  conditionalPattern = /\$\{\s*isset ([a-zA-Z]*) \s*\}(.*)\$\{\s*end\s*\}/g;
  copy = templateString;
  while ((conditionalMatches = conditionalPattern.exec(templateString)) !== null) {
    if (data[conditionalMatches[1]]) {
      copy = copy.replace(conditionalMatches[0], conditionalMatches[2]);
    } else {
      copy = copy.replace(conditionalMatches[0], "");
    }
  }
  templateString = copy;

  var key, find, re;
  for (key in data) {
    find = "\\$\\{\\s*" + key + "\\s*\\}";
    re = new RegExp(find, "g");
    templateString = templateString.replace(re, data[key]);
  }
  return templateString;
}
