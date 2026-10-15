
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

late Box favoritesBox;
late Box createdPostsBox;

const Color xBlack = Color(0xFF000000);
const Color xPanel = Color(0xFF16181C);
const Color xBorder = Color(0xFF2F3336);
const Color xBlue = Color(0xFF1D9BF0);
const Color xMuted = Color(0xFF71767B);
const String postsUrl = 'https://jsonplaceholder.typicode.com/posts';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  favoritesBox = await Hive.openBox('favoritesBox');
  createdPostsBox = await Hive.openBox('createdPostsBox');
  runApp(const PostReaderApp());
}

// ENGLISH SAMPLE POSTS

const List<Map<String, String>> englishPosts = [
  {
    'title': 'The Power of Small Daily Habits',
    'body':
        'Big achievements often begin with small steps. Reading, learning, and practicing every day can create lasting progress. Consistency matters more than perfection.',
  },
  {
    'title': 'Why Learning Never Stops',
    'body':
        'Every day gives us an opportunity to discover something new. Ask questions, explore ideas, and learn from your experiences. Curiosity helps us grow.',
  },
  {
    'title': 'A Guide to Better Time Management',
    'body':
        'Choose your most important tasks, break large projects into smaller steps, and avoid distractions. A simple plan can make your day more productive.',
  },
  {
    'title': 'The Benefits of Reading',
    'body':
        'Reading introduces us to new perspectives, improves vocabulary, and strengthens our understanding of the world. Even a few minutes each day can become a valuable habit.',
  },
  {
    'title': 'Building Confidence Through Practice',
    'body':
        'Confidence grows when we prepare, practice, and learn from mistakes. Keep improving one step at a time and celebrate your progress.',
  },
  {
    'title': 'Exploring the World Around You',
    'body':
        'Discover interesting places, learn about local history, or spend time in nature. Small adventures can create meaningful memories.',
  },
  {
    'title': 'The Value of Teamwork',
    'body':
        'Good teamwork starts with communication, respect, and shared goals. Listen to different ideas and help your teammates overcome challenges.',
  },
  {
    'title': 'Technology and Everyday Life',
    'body':
        'Technology helps people communicate, study, work, and solve problems. Use digital tools responsibly and protect your personal information.',
  },
  {
    'title': 'Simple Ways to Stay Organized',
    'body':
        'Keep your workspace tidy, write down important tasks, and organize your files. Good organization makes it easier to focus on what matters.',
  },
  {
    'title': 'Turning Mistakes Into Lessons',
    'body':
        'Mistakes are a natural part of learning. Look for what you can improve, keep practicing, and use every challenge as an opportunity to grow.',
  },
];

Map<String, dynamic> englishPost(Map post) {
  final id = post['id'] as int;
  final sample = englishPosts[(id - 1) % englishPosts.length];

  return {
    'id': id,
    'title': sample['title']!,
    'body': sample['body']!,
  };
}

// APP

class PostReaderApp extends StatelessWidget {
  const PostReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: xBlack,
        colorScheme: const ColorScheme.dark(
          primary: xBlue,
          surface: xBlack,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: xBlack,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: xPanel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const PostsScreen(),
    );
  }
}

// HOME FEED

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  List<Map<String, dynamic>> posts = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await http.get(Uri.parse(postsUrl));

      if (response.statusCode != 200) {
        throw Exception('Unable to load posts');
      }

      final List data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        posts = data.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Unable to load online posts. Check your connection.';
      });
    }
  }

  // Locally created posts appear before API posts.
  List<Map<String, dynamic>> get feedPosts {
    final localPosts = createdPostsBox.values.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    return [...localPosts.reversed, ...posts];
  }

  void openPost(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsScreen(post: post),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> createPost() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: xBlack,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, refreshSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () =>
                                Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () {
                              final title =
                                  titleController.text.trim();
                              final body =
                                  bodyController.text.trim();

                              if (title.isEmpty || body.isEmpty) {
                                ScaffoldMessenger.of(sheetContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a title and content.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              Navigator.pop(sheetContext, {
                                'title': title,
                                'body': body,
                              });
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: xBlue,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text('Post'),
                          ),
                        ],
                      ),
                      const Text(
                        'Create a post',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF263341),
                            child: Icon(
                              Icons.person,
                              color: xBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: titleController,
                                  maxLength: 100,
                                  decoration: const InputDecoration(
                                    hintText: 'Give your post a title...',
                                    counterText: '',
                                    prefixIcon: Icon(Icons.title),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: bodyController,
                                  maxLines: 5,
                                  maxLength: 1000,
                                  decoration: const InputDecoration(
                                    hintText: "What's happening?",
                                    alignLabelWithHint: true,
                                    prefixIcon: Padding(
                                      padding: EdgeInsets.only(bottom: 75),
                                      child: Icon(Icons.edit_note),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.public, color: xBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Everyone can read this post',
                            style: TextStyle(color: xBlue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    bodyController.dispose();

    if (result == null || !mounted) return;

    final id = DateTime.now().microsecondsSinceEpoch;

    final newPost = <String, dynamic>{
      'id': id,
      'title': result['title']!,
      'body': result['body']!,
      'createdAt': DateTime.now().toIso8601String(),
      'isLocal': true,
    };

    try {
      await createdPostsBox.put(id, newPost);

      if (!mounted) return;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your post was published!'),
        ),
      );

      // Demo API request. The local Hive copy is the persistent copy.
      try {
        await http.post(
          Uri.parse(postsUrl),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'title': result['title'],
            'body': result['body'],
            'userId': 1,
          }),
        );
      } catch (_) {
        // The locally saved post remains available.
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your post. Please try again.'),
        ),
      );
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> post) async {
    final id = post['id'];

    if (favoritesBox.containsKey(id)) {
      await favoritesBox.delete(id);
    } else {
      await favoritesBox.put(id, {
        ...post,
        'note': '',
      });
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final feed = feedPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_stories, color: xBlue, size: 29),
            SizedBox(width: 10),
            Text(
              'Post Reader',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh feed',
            onPressed: fetchPosts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FavoritesScreen(),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
            icon: const Icon(Icons.favorite_border),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createPost,
        backgroundColor: xBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: xBorder),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: xBlue),
                  )
                : RefreshIndicator(
                    color: xBlue,
                    onRefresh: fetchPosts,
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: xBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFF263341),
                                child: Icon(
                                  Icons.person,
                                  color: xBlue,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(30),
                                  onTap: createPost,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      "What's happening?",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: xMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Write a post',
                                onPressed: createPost,
                                icon: const Icon(
                                  Icons.edit_square,
                                  color: xBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (error.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.wifi_off,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Try again',
                                  onPressed: fetchPosts,
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                          ),
                        if (feed.isEmpty && error.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.post_add,
                                  size: 55,
                                  color: xMuted,
                                ),
                                SizedBox(height: 12),
                                Text('No posts yet. Create the first one!'),
                              ],
                            ),
                          ),
                        for (final originalPost in feed)
                          PostCard(
                            post: originalPost['isLocal'] == true
                                ? originalPost
                                : englishPost(originalPost),
                            onTap: () => openPost(
                              originalPost['isLocal'] == true
                                  ? originalPost
                                  : englishPost(originalPost),
                            ),
                            onFavorite: () => toggleFavorite(
                              originalPost['isLocal'] == true
                                  ? originalPost
                                  : englishPost(originalPost),
                            ),
                            isFavorite: favoritesBox.containsKey(
                              originalPost['id'],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// POST CARD

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final bool isFavorite;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onFavorite,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = post['isLocal'] == true;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: xBorder),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isLocal
                  ? const Color(0xFF173D55)
                  : const Color(0xFF263341),
              child: Icon(
                isLocal ? Icons.person : Icons.auto_stories,
                color: xBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Reader Community',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        color: xBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isLocal ? '· Your post' : '· Community post',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: xMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Post options',
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: xPanel,
                            builder: (context) => SafeArea(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.bookmark_border,
                                  color: xBlue,
                                ),
                                title: const Text('Save this post'),
                                onTap: () {
                                  Navigator.pop(context);
                                  onFavorite();
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.more_horiz,
                          color: xMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    post['title']?.toString() ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['body']?.toString() ?? '',
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PostAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'Read',
                        onTap: onTap,
                      ),
                      PostAction(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        label: 'Save',
                        color: isFavorite ? Colors.pinkAccent : xMuted,
                        onTap: onFavorite,
                      ),
                      PostAction(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Share feature coming soon.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const PostAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = xMuted,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// POST DETAILS

class DetailsScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const DetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final id = post['id'];
    final isFavorite = favoritesBox.containsKey(id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF263341),
                child: Icon(Icons.auto_stories, color: xBlue),
              ),
              SizedBox(width: 12),
              Text(
                'Reader Community',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 5),
              Icon(Icons.verified, color: xBlue, size: 16),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            post['title']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            post['body']?.toString() ?? '',
            style: const TextStyle(fontSize: 18, height: 1.8),
          ),
          const SizedBox(height: 24),
          const Divider(color: xBorder),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
            ),
            title: Text(
              isFavorite ? 'Saved to Favorites' : 'Save this post',
            ),
            onTap: () async {
              if (favoritesBox.containsKey(id)) {
                await favoritesBox.delete(id);
              } else {
                await favoritesBox.put(id, {
                  ...post,
                  'note': '',
                });
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      favoritesBox.containsKey(id)
                          ? 'Added to Favorites'
                          : 'Removed from Favorites',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// FAVORITES SCREEN

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> get savedPosts {
    return favoritesBox.values
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList()
        .reversed
        .toList();
  }

  Future<void> editNote(Map<String, dynamic> post) async {
    final controller = TextEditingController(
      text: post['note']?.toString() ?? '',
    );

    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: xPanel,
        title: const Text('Personal Note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write a note about this post...',
            prefixIcon: Icon(Icons.edit_note),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (note == null) return;

    final updated = Map<String, dynamic>.from(post);
    updated['note'] = note;
    await favoritesBox.put(updated['id'], updated);

    if (mounted) setState(() {});
  }

  Future<void> deleteFavorite(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: xPanel,
        title: const Text('Delete Favorite?'),
        content: const Text(
          'This removes the post from your saved favorites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await favoritesBox.delete(post['id']);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final posts = savedPosts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text('Your Favorites'),
          ],
        ),
      ),
      body: posts.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 65,
                    color: xMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nothing saved yet',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Save a post and it will appear here.',
                    style: TextStyle(color: xMuted),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                for (final post in posts)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: xBorder),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(post['body']?.toString() ?? ''),
                        if ((post['note']?.toString() ?? '').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Note: ${post['note']}',
                            style: const TextStyle(color: xMuted),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => editNote(post),
                              icon: const Icon(Icons.edit_note),
                              label: const Text('Edit Note'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => deleteFavorite(post),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              label: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
