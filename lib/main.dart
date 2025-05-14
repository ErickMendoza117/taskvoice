import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import 'login_screen.dart'; // Import LoginScreen
import 'registration_screen.dart'; // Import RegistrationScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

// Define states for the speech recognition process
enum SpeechState {
  idle,
  listeningForCommand,
  listeningForTaskDescription,
  listeningForTaskNumber,
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskVoice POC',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/':
            (context) =>
                const AuthWrapper(), // Use AuthWrapper to handle auth state
        '/login': (context) => const LoginScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/tasks': (context) => const TasksScreen(), // Main task screen
      },
    );
  }
}

// Widget to wrap the main content and handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is signed in
          return const TasksScreen(); // Show the main task screen
        } else {
          // User is signed out
          return const LoginScreen(); // Show the login screen
        }
      },
    );
  }
}

// The main task screen content (extracted from the original _MainAppState build method)
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  SpeechState _speechState = SpeechState.idle; // Add state variable
  Color _containerColor = Colors.transparent; // Add color state variable

  // Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Removed _subscribeToTasks() call
  }

  /// This has to happen only once or we will get errors.
  void _initSpeech() async {
    print('Initializing speech recognition...');
    _speechEnabled = await _speechToText.initialize();
    print('Speech recognition initialized: $_speechEnabled');
    // No automatic start listening here
    setState(() {});
  }

  // Removed _subscribeToTasks method

  @override
  void dispose() {
    // Removed _taskSubscription?.cancel()
    super.dispose();
  }

  /// Each time to start a speech control session
  void _startListening() async {
    if (!_speechEnabled) {
      print('Speech recognition not enabled.');
      return;
    }
    print('Starting to listen...');
    _lastWords = ''; // Clear previous words
    await _speechToText.listen(
      onResult: _onSpeechResult,
      // onError and onStatus parameters are not available in this version.
      // Error and status handling might be done differently.
    );
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that will stop the session
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns speech recognition results.
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        if (_speechState == SpeechState.listeningForCommand) {
          // Check for the 'new task' command
          if (_lastWords.toLowerCase() == 'new task') {
            _speechState = SpeechState.listeningForTaskDescription;
            _lastWords = 'Say the task description...'; // Update status text
            // Optionally stop and restart listening for a cleaner capture
            _speechToText.stop().then((_) {
              _startListening();
            });
          } else if (_lastWords.toLowerCase() == 'new shopping') {
            // Add shopping command recognized
            _speechState = SpeechState.listeningForTaskDescription;
            _lastWords = 'Say the shopping item...'; // Update status text
            // Optionally stop and restart listening for a cleaner capture
            _speechToText.stop().then((_) {
              _startListening();
            });
          } else if (_lastWords.toLowerCase() == 'clear task') {
            // Clear tasks command recognized
            // Delete all documents in the 'tasks' collection for the current user
            if (FirebaseAuth.instance.currentUser != null) {
              _db
                  .collection('tasks')
                  .where(
                    'userId',
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )
                  .get()
                  .then((snapshot) {
                    for (DocumentSnapshot doc in snapshot.docs) {
                      doc.reference.delete();
                    }
                    print(
                      'All tasks cleared from Firestore for user.',
                    ); // Log to confirm clearing
                    _speechState = SpeechState.idle; // Go back to idle
                    _lastWords = 'All tasks cleared.'; // Confirmation message
                    setState(() {}); // Update UI
                  })
                  .catchError((error) {
                    print('Failed to clear tasks: $error');
                    _lastWords = 'Failed to clear tasks.';
                    setState(() {}); // Update UI with error message
                  });
            } else {
              _lastWords = 'User not logged in.';
              setState(() {});
            }
            _stopListening(); // Stop listening after command
          } else if (_lastWords.toLowerCase() == 'remove task') {
            // Remove task command recognized
            // We need the current list of tasks to remove by number.
            // This logic will need to be adjusted to work with the StreamBuilder's data.
            // For now, we'll leave a placeholder or a simplified approach.
            // A better approach might involve displaying task numbers in the UI
            // and having the user say the number, then finding the corresponding
            // document ID from the StreamBuilder's snapshot data.
            _lastWords = 'Remove task command requires list data.';
            _speechState = SpeechState.idle;
            _stopListening();

            /*
            // Original logic (commented out as _firestoreTasks is removed)
            if (_firestoreTasks.isEmpty) {
              _speechState = SpeechState.idle;
              _lastWords = 'No tasks to remove.';
              _stopListening();
            } else {
              _speechState = SpeechState.listeningForTaskNumber;
              _lastWords =
                  'Say the number of the task to remove...'; // Prompt for number
              // Removed stop and restart listening to capture the number immediately
            }
            */
          } else {
            // Command not recognized, go back to idle
            _speechState = SpeechState.idle;
            _lastWords =
                'Command not recognized. Press button to start.'; // Update status text
            _stopListening(); // Stop listening if command not recognized
          }
        } else if (_speechState == SpeechState.listeningForTaskDescription) {
          // Capture the task description
          final taskDescription = _lastWords.trim();
          if (taskDescription.isNotEmpty &&
              taskDescription.toLowerCase() != 'say the task description...') {
            // Add task to Firestore
            if (FirebaseAuth.instance.currentUser != null) {
              _db
                  .collection('tasks')
                  .add({
                    'description': taskDescription,
                    'timestamp':
                        FieldValue.serverTimestamp(), // Add a timestamp
                    'userId':
                        FirebaseAuth.instance.currentUser!.uid, // Add user ID
                  })
                  .then((_) {
                    // On success, add to local list and update UI
                    print(
                      'Task added: $taskDescription',
                    ); // Log to confirm task addition
                    _lastWords =
                        'Task added: $taskDescription'; // Confirmation message
                    // Temporarily change container color to indicate task added
                    _containerColor = Colors.greenAccent;
                    Future.delayed(const Duration(milliseconds: 500), () {
                      setState(() {
                        _containerColor = Colors.transparent;
                      });
                    });
                    setState(() {}); // Update UI after adding task
                  })
                  .catchError((error) {
                    // Handle errors
                    print('Failed to add task: $error');
                    _lastWords = 'Failed to add task.';
                    setState(() {}); // Update UI with error message
                  });
            } else {
              _lastWords = 'User not logged in. Cannot add task.';
              setState(() {});
            }
          } else {
            _lastWords =
                'No task description captured.'; // Handle empty description
            setState(() {}); // Update UI
          }
          _speechState =
              SpeechState.idle; // Go back to idle after capturing task
          _stopListening(); // Stop listening after capturing task
        } else if (_speechState == SpeechState.listeningForTaskNumber) {
          // This logic also needs adjustment to work with StreamBuilder data.
          // We cannot directly access _firestoreTasks here anymore.
          _lastWords = 'Remove task by number requires list data.';
          _speechState = SpeechState.idle;
          _stopListening();

          /*
          print(
            'Recognized number text: $_lastWords',
          ); // Log recognized text for number
          // Try to parse the recognized words as a number
          final recognizedNumber = int.tryParse(_lastWords.trim());
          if (recognizedNumber != null) {
            // Adjust for 0-based index
            final taskIndexToRemove = recognizedNumber - 1;
            if (taskIndexToRemove >= 0 &&
                taskIndexToRemove < _firestoreTasks.length) {
              // Valid index, remove the task from Firestore
              final taskIdToRemove = _firestoreTasks[taskIndexToRemove].id;
              _db
                  .collection('tasks')
                  .doc(taskIdToRemove)
                  .delete()
                  .then((_) {
                    print(
                      'Task removed: ${_firestoreTasks[taskIndexToRemove]['description']}',
                    ); // Log to confirm removal
                    _lastWords =
                        'Removed task number $recognizedNumber.'; // Confirmation message
                    setState(() {}); // Update UI after removing task
                  })
                  .catchError((error) {
                    print('Failed to remove task: $error');
                    _lastWords = 'Failed to remove task.';
                    setState(() {}); // Update UI with error message
                  });
            } else {
              // Invalid task number
              _lastWords = 'Invalid task number.';
              setState(() {}); // Update UI
            }
          } else {
            // Not a valid number
            _lastWords = 'Could not understand the number.';
            setState(() {}); // Update UI
          }
          _speechState =
              SpeechState.idle; // Go back to idle after processing number
          _stopListening(); // Stop listening after processing number
          */
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user's UID
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // If user is not logged in, show a message or navigate away (AuthWrapper handles navigation)
    if (userId == null) {
      return const Center(child: Text('Please log in to see tasks.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskVoice POC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigation will be handled by AuthWrapper
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              color: _containerColor, // Apply the color state variable
              child: Text(
                'Recognized words: $_lastWords',
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              // Add background color to Expanded to visualize list area
              child: Container(
                color: Colors.grey[200], // Light grey background
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _db
                          .collection('tasks')
                          .where(
                            'userId',
                            isEqualTo: userId,
                          ) // Filter by user ID
                          .orderBy(
                            'timestamp',
                            descending: true,
                          ) // Order by timestamp
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Data is available, build the list
                    final tasks = snapshot.data!.docs;

                    // Note: The 'remove task' voice command logic needs to be updated
                    // to work with the 'tasks' list from this snapshot.
                    // For now, the voice command for removing tasks is disabled/placeholder.

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        // Display task number (index + 1) and task description from Firestore data
                        final task =
                            tasks[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text('${index + 1}. ${task['description']}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _speechToText.isListening
                ? _stopListening
                : () {
                  _speechState =
                      SpeechState
                          .listeningForCommand; // Set state to listen for command
                  _lastWords = 'Say "new task"...'; // Update status text
                  _startListening(); // Start listening
                },
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}
