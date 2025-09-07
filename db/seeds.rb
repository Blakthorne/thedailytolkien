# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# For "The Daily Tolkien", we seed the database with a selection of quotes from J.R.R. Tolkien's works.
# These quotes provide initial content for the application and demonstrate the data structure.
# In a real application, quotes might be imported from a larger dataset or added via an admin interface.

# Sample quotes from various Tolkien works
quotes = [
  # Page 1
  {
    text: "It is perilous to study too deeply the arts of the Enemy, for good or for ill. But such falls and betrayals, alas, have happened before.",
    book: "The Fellowship of the Ring",
    chapter: "The Council of Elrond",
    character: "Elrond"
  },
  {
    text: "Go not to the Elves for counsel, for they will say both no and yes.",
    book: "The Fellowship of the Ring",
    chapter: "Three is Company",
    character: "Frodo"
  },
  {
    text: "Faithless is he that says farewell when the road darkens",
    book: "The Fellowship of the Ring",
    chapter: "The Ring goes South",
    character: nil
  },
  {
    text: "He that breaks a thing to find out what it is has left the path of wisdom.",
    book: "The Fellowship of the Ring",
    chapter: "Council of Elrond",
    character: "Gandalf"
  },
  {
    text: "Deserves it! I dare say he does. Many that live deserve death and some that die deserve life. Can you give it to them? Then do not be so eager to deal out death in judgement. For even the wise cannot see all ends.",
    book: "The Fellowship of the Ring",
    chapter: "The Shadow of the Past",
    character: nil
  },
  {
    text: "Do not meddle in the affairs of Wizards, for they are subtle and quick to anger.",
    book: "The Fellowship of the Ring",
    chapter: "Three is Company",
    character: "Gildor"
  },
  {
    text: "Hill. Yes, that was it. But it is a hasty word for a thing that has stood here ever since this part of the world was shaped.",
    book: "The Two Towers",
    chapter: "Treebeard",
    character: "Treebeard"
  },
  {
    text: "The praise of the praiseworthy is above all rewards.",
    book: "The Two Towers",
    chapter: "The Window on the West",
    character: nil
  },
  {
    text: "Well, here at last, dear friends, on the shores of the sea comes the end of our fellowship in middle-earth. Go in peace! I will not say: do not weep for not all tears are an evil.",
    book: "The Return of the King",
    chapter: "The Grey Havens",
    character: "Gandalf"
  },
  {
    text: "Far over the misty mountains cold\nTo dungeons deep and caverns old\nWe must away ere break of day\nTo seek the pale enchanted gold.",
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: nil
  },
  # Page 2
  {
    text: "Still round the corner there may wait\nA new road or a secret gate\nAnd though I oft have passed them by\nThe day will come at last when I\nShall take the hidden paths that run\nWest of the Moon and East of the Sun.",
    book: "The Return of the King",
    chapter: "The Grey Havens",
    character: nil
  },
  {
    text: "'I wish it need not have happened in my time,' said Frodo.\n'So do I,' said Gandalf, 'and so do all who live to see such times. But that is not for them to decide. All we have to decide is what to do with the time that is given us.'",
    book: "The Fellowship of the Ring",
    chapter: "The Shadow of the Past",
    character: "Gandalf"
  },
  {
    text: "Seldom give unguarded advice, for advice is a dangerous gift, even from the wise to the wise, and all courses may run ill.",
    book: "The Fellowship of the Ring",
    chapter: "Three is Company",
    character: "Gildor"
  },
  {
    text: "All that is gold does not glitter,\nNot all those who wander are lost;\nThe old that is strong does not wither,\nDeep roots are not reached by the frost.\nFrom the ashes a fire shall be woken,\nA light from the shadows shall spring;\nRenewed shall be blade that was broken,\nThe crownless again shall be king.",
    book: "The Fellowship of the Ring",
    chapter: "Strider",
    character: nil
  },
  {
    text: "I do not love the bright sword for its sharpness, nor the arrow for its swiftness, nor the warrior for his glory. I love only that which they defend.",
    book: "The Two Towers",
    chapter: "The Window on the West",
    character: nil
  },
  {
    text: "I am looking for someone to share in an adventure that I am arranging, and it's very difficult to find anyone.",
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: "Gandalf"
  },
  # Page 3
  {
    text: "It's the job that's never started as takes longest to finish.",
    book: "The Fellowship of the Ring",
    chapter: "The Mirror of Galadriel",
    character: nil
  },
  {
    text: "Gandalf was shorter in stature than the other two; but his long white hair, his sweeping silver beard, and his broad shoulders, made him look like some wise king of ancient legend. In his aged face under great snowy brows his eyes were set like coals that could suddenly burst into fire.",
    book: "The Fellowship of the Ring",
    chapter: "Many Meetings",
    character: nil
  },
  {
    text: "Some say that he is a bear descended from the great and ancient bears of the mountains that lived there before the giants came, Others say he is a man descended from the first men who lived before Smaug or the other dragons came into this part oft he world, and before the goblins came into the hills out of the North. I cannot say, though I fancy the last is the true tale.",
    book: "The Hobbit",
    chapter: "Queer Lodgings",
    character: "Gandalf"
  },
  {
    text: "I once saw him sitting alone on the top of the Carrock at night watching the the moon sinking towards the Misty Mountains, and I heard him growl in the tongue of bears: \"The day will come when they will perish and I shall go back!\" That is why I believe he once came from the mountains himself.",
    book: "The Hobbit",
    chapter: "Queer Lodgings",
    character: "Gandalf"
  },
  {
    text: "Deserves it! I daresay he does. Many that live deserve death. And some that die deserve life. Can you give it to them? Then do not be too eager to deal out death in judgement. For even the very wise cannot see all ends. I have not much hope that Gollum can be cured before he dies, but there is a chance of it. And he is bound up with the fate of the Ring. My heart tells me that he has some part to play yet, for good or ill, before the end; and when that comes, the pity of Bilbo may rule the fate of many — yours not least.",
    book: "The Fellowship of the Ring",
    chapter: "The Shadow of the Past",
    character: "Gandalf"
  },
  {
    text: '"Good morning!" said Bilbo, and he meant it. The sun was shining, and the grass was very green. But Gandalf looked at him from under long bushy eyebrows that stuck out farther than the brim of his shady hat.
"What do you mean?" he said. "Do you wish me a good morning, or mean that it is a good morning whether I want it or not; or that you feel good this morning; or that it is a morning to be good on?"
"All of them at once," said Bilbo.',
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: nil
  },
  {
    text: "I kill where I wish and none dare resist. I laid low the warriors of old and their like is not in the world today. Then I was but young and tender. Now I am old and strong, strong strong.",
    book: "The Hobbit",
    chapter: "Inside Information",
    character: "Smaug"
  },
  {
    text: "There were lots of dragons in the North in those days, and gold was probably getting scarce up there, with the dwarves flying south or getting killed, and all the general waste and destruction that dragons make going from bad to worse. There was a most specially greedy, strong and wicked worm called Smaug.",
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: "Thorin"
  },
  {
    text: "My armour is like tenfold shields, my teeth are swords, my claws spears, the shock of my tail is a thunderbolt, my wings a hurricane, and my breath death!",
    book: "The Hobbit",
    chapter: "Inside Information",
    character: "Smaug"
  },
  {
    text: "Take him away and keep him safe, until he feels inclined to tell the truth, even if he waits a hundred years.",
    book: "The Hobbit",
    chapter: "Flies and Spiders",
    character: "Thranduil about Thorin"
  },
  # Page 4
  {
    text: "You are more worthy to wear the armour of elf-princes than many that have looked more comely in it.",
    book: "The Hobbit",
    chapter: "A Thief in the Night",
    character: "Thranduil to Bilbo"
  },
  {
    text: "Sauron was become now a sorcerer of dreadful power, master of shadows and of phantoms, foul in wisdom, cruel in strength, misshaping what he touched, twisting what he ruled, lord of werewolves; his dominion was torment. He took Minas Tirith by assault, for a dark cloud of fear fell upon those that defended it; and Orodreth was driven out, and fled to Nargothrond.",
    book: "The Silmarillion",
    chapter: "Quenta Silmarillion: Of the Ruin of Beleriand and the Fall of Fingolfin",
    character: "About Sauron"
  },
  {
    text: "But do you remember Gandalf's words: Even Gollum may have something yet to do? But for him, Sam, I could not have destroyed the Ring. The Quest would have been in vain, even at the bitter end. So let us forgive him! For the Quest is achieved and now all is over. I am glad you are here with me. Here at the end of all things, Sam.",
    book: "The Return of the King",
    chapter: "Mount Doom",
    character: "Frodo"
  },
  {
    text: "In a hole in the ground there lived a hobbit. Not a nasty, dirty, wet hole, filled with the ends of worms and an oozy smell, nor yet a dry, bare, sandy hole with nothing in it to sit down on or to eat: it was a hobbit-hole, and that means comfort.",
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: nil
  },
  {
    text: "That is a fair lord and a great captain of men. If Gondor has such men still in these days of fading, great must have been its glory in the days of its rising.",
    book: "The Return of the King",
    chapter: "The Last Debate",
    character: "Legolas about Prince Imrahil"
  },
  {
    text: "Morgoth held hurled aloft Grond, Hammer of the Underworld, and swung it down like a bolt of thunder. But Fingolfin sprang aside, and Grond rent a mighty pit in the earth, whence smoke and fire darted. Many times Morgoth essayed to smite him, and each time Fingolfin leaped away, as a lightning shoots from under dark cloud; and he wounded Morgoth with seven wounds, and seven times Morgoth gave a cry of anguish, whereat the hosts of Angband fell upon their faces in dismay, and the cries echoed in the Northlands.",
    book: "The Silmarillion",
    chapter: "Quenta Silmarillion: Of the Ruin of Beleriand and the Fall of Fingolfin",
    character: nil
  },
  {
    text: "And now at last it comes. You will give me the Ring freely! In place of the Dark Lord you will set up a Queen. And I shall not be dark, but beautiful and terrible as the Morning and the Night! Fair as the Sea and the Sun and the Snow upon the Mountain! Dreadful as the Storm and the Lightning! Stronger than the foundations of the earth. All shall love me and despair!",
    book: "The Fellowship of the Ring",
    chapter: "The Mirror of Galadriel",
    character: "Galadriel"
  },
  {
    text: 'I have come," he said. "But I do not choose now to do what I came to do. I will not do this deed. The Ring is mine!" And suddenly, as he set it on his finger, he vanished from Sam\'s sight.',
    book: "The Return of the King",
    chapter: "Mount Doom",
    character: "Frodo"
  },
  {
    text: "Seek for the Sword that was broken:\nIn Imladris it dwells;\nThere shall be counsels taken\nStronger than Morgul-spells.\nThere shall be shown a token\nThat Doom is near at hand,\nFor Isildur's Bane shall waken,\nAnd the Halfling forth shall stand.",
    book: "The Fellowship of the Ring",
    chapter: "The Council of Elrond",
    character: nil
  },
  {
    text: '"You cannot pass," he said. The orcs stood still, and a dead silence fell. "I am a servant of the Secret Fire, wielder of the flame of Anor. You cannot pass. The dark fire will not avail you, flame of Udûn. Go back to the Shadow! You cannot pass."',
    book: "The Fellowship of the Ring",
    chapter: "The Bridge of Khazad-dûm",
    character: "Gandalf"
  },
  # Page 5
  {
    text: "Sorry! I don't want any adventures, thank you. Not Today. Good morning! But please come to tea — any time you like! Why not tomorrow? Good bye!",
    book: "The Hobbit",
    chapter: "An Unexpected Party",
    character: "Bilbo Baggins"
  },
  {
    text: "Bother burgling and everything to do with it! I wish I was at home in my nice hole by the fire, with the kettle just beginning to sing!",
    book: "The Hobbit",
    chapter: "Roast Mutton",
    character: "Bilbo Baggins"
  },
  {
    text: "'I am old, Gandalf. I don't look it, but I am beginning to feel it in my heart of hearts. Well-preserved indeed!' he snorted. 'Why, I feel all thin, sort of stretched, if you know what I mean: like butter that has been scraped over too much bread. That can't be right. I need a change, or something.'",
    book: "The Fellowship of the Ring",
    chapter: "A Long-expected Party",
    character: "Bilbo Baggins"
  },
  {
    text: "Now news came to Hithlum that Dorthonion was lost and the sons of Finarfin overthrown, and that the sons of Fëanor were driven from their lands. Then Fingolfin beheld… the utter ruin of the Noldor, and the defeat beyond redress of all their houses; and filled with wrath and despair he mounted upon Rochallor his great horse and rode forth alone, and none might restrain him. He passed over Dor-nu-Fauglith like a wind amid the dust, and all that beheld his onset fled in amaze, thinking that Oromë himself was come: for a great madness of rage was upon him, so that his eyes shone like the eyes of the Valar. Thus he came alone to Angband's gates, and he sounded his horn, and smote once more upon the brazen doors, and challenged Morgoth to come forth to single combat. And Morgoth came.",
    book: "The Silmarillion",
    chapter: "Quenta Silmarillion: Of the Ruin of Beleriand and the Fall of Fingolfin",
    character: nil
  },
  {
    text: "Come not between the Nazgûl and his prey! Or he will not slay thee in thy turn. He will bear thee away to the houses of lamentation, beyond all darkness, where thy flesh shall be devoured, and thy shriveled mind be left naked to the Lidless Eye.",
    book: "The Return of the King",
    chapter: "The Battle of the Pelennor Fields",
    character: "The Witch-King of Angmar to Éowyn"
  },
  {
    text: "A man that flies from his fear may find that he has only taken a short cut to meet it.",
    book: "The Children of Hurin",
    chapter: "The Childhood of Túrin",
    character: "Sador on loosing a leg by accident after fleeing battle"
  },
  {
    text: "I cordially dislike allegory in all its manifestations, and always have done since I grew old and wary enough to detect its presence.",
    book: "The Lord of the Rings",
    chapter: "Foreword to the Second Edition",
    character: nil
  },
  {
    text: "Some who have read the book, or at any rate have reviewed it, have found it boring, absurd, or contemptible; and I have no cause to complain, since I have similar opinions of their works, or of the kinds of writing that they evidently prefer.",
    book: "The Lord of the Rings",
    chapter: "Foreword to the Second Edition",
    character: nil
  },
  {
    text: "It was like discovering a complete wine-filled cellar filled with bottles of an amazing wine of a kind and flavor never tasted before. It quite intoxicated me [...]",
    book: "The Letters of J.R.R. Tolkien",
    chapter: "No. 163",
    character: nil
  },
  {
    text: "Never laugh at live dragons, Bilbo you fool!",
    book: "The Hobbit",
    chapter: "Inside Information",
    character: "Bilbo"
  },
  # Page 6
  {
    text: "The Black Rider flung back his hood, and behold! he had a kingly crown; and yet upon no head visible was it set. The red fires shone between it and the mantled shoulders vast and dark. From a mouth unseen there came a deadly laughter.\n'Old fool!' he said. 'Old fool! This is my hour. Do you not know Death when you see it? Die now and curse in vain!' And with that he lifted high his sword and flames ran down the blade.",
    book: "The Return of the King",
    chapter: "The Siege of Gondor",
    character: "Gandalf's encounter with The Witch-King of Angmar"
  },
  {
    text: "Three Rings for the Elven-kings under the sky,\nSeven for the Dwarf-lords in their halls of stone,\nNine for Mortal Men doomed to die,\nOne for the Dark Lord in his dark throne\nIn the Land of Mordor where the Shadows lie.\nOne Ring to rule them all, One Ring to find them,\nOne ring to bring them all and in the darkness bind them\nIn the Land of Mordor where the Shadows lie.",
    book: "The Fellowship of the Ring",
    chapter: "The Shadow of the Past",
    character: nil
  },
  {
    text: "Old Tom Bombadil is a merry fellow,\nBright blue his jacket is, and his boots are yellow.\nNone has ever caught him yet, for Tom, he is the master:\nHis songs are stronger songs, and his feet are faster.",
    book: "The Fellowship of the Ring",
    chapter: "Fog on the Barrow Downs",
    character: "Tom Bombadil"
  },
  {
    text: "'It was a compliment,' said Merry Brandybuck, 'and so, of course, not true.'",
    book: "The Fellowship of the Ring",
    chapter: "A Long-expected Party",
    character: "Merry Brandybuck"
  },
  {
    text: "The invention of languages is the foundation. The 'stories' were made rather to provide a world for the languages than the reverse. To me a name comes first and the story follows.",
    book: "The Letters of J.R.R. Tolkien",
    chapter: "No. 165",
    character: nil
  },
  {
    text: "Thank you for your letter ... I regret that I am not clear as to what you intend by arisch. I am not of Aryan extraction: that is Indo-Iranian; as far as I am aware none of my ancestors spoke Hindustani, Persian, Gypsy, or any related dialects. But if I am to understand that you are enquiring whether I am of Jewish origin, I can only reply that I regret that I appear to *no* ancestors of that gifted people.",
    book: "The Letters of J.R.R. Tolkien",
    chapter: "No. 30",
    character: nil
  },
  {
    text: "It is not our part to master all the tides of the world, but to do what is in us for the succour of those years wherein we are set, uprooting the evil in the fields that we know, so that those who live after may have clean earth to till. What weather they shall have is not ours to rule.",
    book: "The Return of the King",
    chapter: "The Last Debate",
    character: "Gandalf"
  },
  {
    text: "He often used to say there was only one Road; that it was like a great river: its springs were at every doorstep and every path was its tributary. 'It's a dangerous business, Frodo, going out of your door,' he used to say. 'You step into the Road, and if you don't keep your feet, there is no telling where you might be swept off to.'",
    book: "The Fellowship of the Ring",
    chapter: "Three Is Company",
    character: "Frodo Baggins"
  },
  {
    text: "Many are the strange chances of the world,' said Mithrandir, 'and help oft shall come from the hands of the weak when the Wise falter.",
    book: "The Silmarillion",
    chapter: "Of the Rings of Power and the Third Age",
    character: "Gandalf"
  },
  {
    text: "Deeds will not be less valiant because they are unpraised.",
    book: "The Return of the King",
    chapter: "The Passing of the Grey Company",
    character: "Aragorn"
  },
  # Page 7
  {
    text: "Such is oft the course of deeds that move the wheels of the world: small hands do them because they must, while the eyes of the great are elsewhere.",
    book: "The Fellowship of the Ring",
    chapter: "The Ring Goes South",
    character: "Elrond"
  },
  {
    text: "The world is indeed full of peril, and in it there are many dark places; but still there is much that is fair, and though in all lands love is now mingled with grief, it grows perhaps the greater.",
    book: "The Fellowship of the Ring",
    chapter: "Lothlórien",
    character: "Haldir"
  }
]

# Create the quotes in the database
quotes.each do |quote_attrs|
  Quote.find_or_create_by!(text: quote_attrs[:text]) do |quote|
    quote.book = quote_attrs[:book]
    quote.chapter = quote_attrs[:chapter]
    quote.character = quote_attrs[:character]
    quote.context = quote_attrs[:context]
    quote.days_displayed = 0  # Initialize display count
    # last_date_displayed and first_date_displayed will be nil initially
  end
end

# Skip user creation in test environment to avoid unique constraint violations
# in parallel test execution. Tests should use fixtures for test data.
unless Rails.env.test?
  # Create admin user
  if User.find_by(email: 'admin@thedailytolkien.com').nil?
    User.create!(
      name: 'Admin User',
      email: 'admin@thedailytolkien.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'admin'
    )
    puts "Admin user created: admin@thedailytolkien.com / password123"
  end

  # Create sample commentor user
  if User.find_by(email: 'user@thedailytolkien.com').nil?
    User.create!(
      name: 'Sample User',
      email: 'user@thedailytolkien.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'commentor'
    )
    puts "Sample user created: user@thedailytolkien.com / password123"
  end
end
