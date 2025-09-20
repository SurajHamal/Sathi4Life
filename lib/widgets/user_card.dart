import 'package:flutter/material.dart';
import '../models/user_card_profile.dart';

class UserCard extends StatelessWidget {
  final UserCardProfile user;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const UserCard({
    Key? key,
    required this.user,
    this.onLike,
    this.onPass,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Profile Image
          Positioned.fill(
            child: user.profileImageUrl.isNotEmpty
                ? Image.network(
              user.profileImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.person, size: 80, color: Colors.grey[600]),
                );
              },
            )
                : Container(
              color: Colors.grey[300],
              child: Icon(Icons.person, size: 80, color: Colors.grey[600]),
            ),
          ),

          // Gradient overlay bottom for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Name, age, gender, bio
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.name}, ${user.age}',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.gender,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      user.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          // Like and Pass buttons bottom left/right
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red, size: 30),
                  onPressed: onPass,
                  tooltip: 'Pass',
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.favorite, color: Colors.green, size: 30),
                  onPressed: onLike,
                  tooltip: 'Like',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
