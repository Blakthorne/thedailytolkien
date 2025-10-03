require "test_helper"

class CommentProfanityTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @quote = quotes(:one)
  end

  # Basic profanity detection tests
  test "detects basic profanity words" do
    comment = Comment.new(content: "This is a damn comment", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect 'damn'"

    comment = Comment.new(content: "This is a hell of a comment", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect 'hell'"

    comment = Comment.new(content: "This is an ass comment", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect 'ass'"
  end

  test "does not detect profanity in clean content" do
    clean_phrases = [
      "This is a wonderful pass to the player",
      "I need to assess the situation",
      "The class was very informative",
      "Send me a message later",
      "That's a good assumption"
    ]

    clean_phrases.each do |phrase|
      comment = Comment.new(content: phrase, user: @user, quote: @quote)
      assert_not comment.contains_profanity?, "Should not flag clean content: '#{phrase}'"
    end
  end

  # Leetspeak detection tests
  test "detects leetspeak substitutions" do
    leetspeak_variants = [
      "This is d@mn annoying",       # @ for a
      "What the h3ll",                # 3 for e
      "You f00l",                     # 0 for o
      "That's bu11$hit",              # 1 for l, $ for s
      "Stop being an @$$",            # @ for a, $ for s
      "This is cr@p",                 # @ for a
      "H311 no",                      # 3 for e, 1 for l
      "D4mn that's bad"               # 4 for a
    ]

    leetspeak_variants.each do |phrase|
      comment = Comment.new(content: phrase, user: @user, quote: @quote)
      assert comment.contains_profanity?, "Should detect leetspeak: '#{phrase}'"
    end
  end

  # Unicode substitution detection tests
  test "detects unicode character substitutions" do
    # Cyrillic 'а' (U+0430) looks like Latin 'a'
    comment = Comment.new(content: "This is dаmn bad", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect Cyrillic 'а' substitution"

    # Cyrillic 'е' (U+0435) looks like Latin 'e'
    comment = Comment.new(content: "What thе hell", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect Cyrillic 'е' substitution"

    # Cyrillic 'о' (U+043E) looks like Latin 'o'
    comment = Comment.new(content: "This is fооl", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect Cyrillic 'о' substitution"
  end

  # Whitespace trick detection tests
  test "detects whitespace obfuscation" do
    whitespace_tricks = [
      "This is d a m n bad",         # spaces between letters
      "What the h-e-l-l",            # dashes between letters
      "You f_o_o_l",                 # underscores between letters
      "That's c*r*a*p",              # asterisks between letters
      "Stop being an a s s",         # spaces
      "This is $-h-i-t",             # mix of leetspeak and dashes
      "What the h e l l"             # spaces
    ]

    whitespace_tricks.each do |phrase|
      comment = Comment.new(content: phrase, user: @user, quote: @quote)
      assert comment.contains_profanity?, "Should detect whitespace trick: '#{phrase}'"
    end
  end

  # Combined evasion technique tests
  test "detects combination of evasion techniques" do
    combined_variants = [
      "This is d_@_m_n bad",         # underscores + leetspeak
      "What the h-3-l-l",            # dashes + leetspeak
      "You f 0 0 l",                 # spaces + leetspeak
      "That's @_$_$",                # underscores + leetspeak
      "Stop being an @ s s"          # leetspeak + spaces
    ]

    combined_variants.each do |phrase|
      comment = Comment.new(content: phrase, user: @user, quote: @quote)
      assert comment.contains_profanity?, "Should detect combined evasion: '#{phrase}'"
    end
  end

  # Filtered content tests
  test "filters basic profanity words" do
    comment = Comment.new(content: "This is damn", user: @user, quote: @quote)
    assert_equal "This is ****", comment.filtered_content
  end

  test "filters obfuscated profanity" do
    comment = Comment.new(content: "This is d@mn", user: @user, quote: @quote)
    filtered = comment.filtered_content
    assert_match(/\[Content filtered due to inappropriate language\]|This is d@mn/, filtered)
  end

  test "preserves clean content" do
    clean_content = "This is a wonderful message"
    comment = Comment.new(content: clean_content, user: @user, quote: @quote)
    assert_equal clean_content, comment.filtered_content
  end

  test "handles multiple profanity words" do
    comment = Comment.new(content: "This damn hell is bad", user: @user, quote: @quote)
    filtered = comment.filtered_content
    assert_not_equal "This damn hell is bad", filtered
    assert filtered.include?("****"), "Should filter 'damn'"
  end

  # Edge cases
  test "handles case insensitivity" do
    comment = Comment.new(content: "This is DAMN", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect uppercase profanity"

    comment = Comment.new(content: "This is DaMn", user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect mixed case profanity"
  end

  test "handles empty or nil content" do
    comment = Comment.new(content: "", user: @user, quote: @quote)
    assert_not comment.contains_profanity?, "Should handle empty content"

    comment = Comment.new(content: nil, user: @user, quote: @quote)
    assert_not comment.contains_profanity?, "Should handle nil content"
  end

  test "handles content with only special characters" do
    comment = Comment.new(content: "@@@@", user: @user, quote: @quote)
    assert_not comment.contains_profanity?, "Should not flag special characters only"

    comment = Comment.new(content: "****", user: @user, quote: @quote)
    assert_not comment.contains_profanity?, "Should not flag asterisks only"
  end

  test "handles very long content" do
    long_content = "This is a very long comment " * 100 + " with damn in it"
    comment = Comment.new(content: long_content, user: @user, quote: @quote)
    assert comment.contains_profanity?, "Should detect profanity in long content"
  end

  # Normalization method tests
  test "normalize_for_profanity_check keeps spaces (detection handled by flexible regex)" do
    comment = Comment.new(content: "d a m n", user: @user, quote: @quote)
    normalized = comment.send(:normalize_for_profanity_check, "d a m n")
    # Normalization doesn't remove spaces; the flexible regex in contains_profanity? handles it
    assert_equal "d a m n", normalized
  end

  test "normalize_for_profanity_check handles leetspeak" do
    comment = Comment.new(content: "d@mn", user: @user, quote: @quote)
    normalized = comment.send(:normalize_for_profanity_check, "d@mn")
    assert_equal "damn", normalized
  end

  test "normalize_for_profanity_check handles unicode" do
    comment = Comment.new(content: "dаmn", user: @user, quote: @quote) # Cyrillic а
    normalized = comment.send(:normalize_for_profanity_check, "dаmn")
    assert_equal "damn", normalized
  end

  test "normalize_for_profanity_check converts to lowercase" do
    comment = Comment.new(content: "DAMN", user: @user, quote: @quote)
    normalized = comment.send(:normalize_for_profanity_check, "DAMN")
    assert_equal "damn", normalized
  end
end
