import 'package:flutter/material.dart';

class GuideFeature {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> bulletPoints;

  GuideFeature({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.bulletPoints,
  });
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ==========================================
    // MODULAR FEATURE LIST
    // Easily add new features here in the future!
    // ==========================================
    final List<GuideFeature> features = [
      GuideFeature(
        title: '1. Adding Exams & AI Auto-Fill',
        icon: Icons.auto_awesome,
        color: Colors.purple,
        description: 'Save time by letting AI read the official notification PDFs for you.',
        bulletPoints: [
          'Tap the "+ Add Exam" button on the dashboard.',
          'Click the "Auto-Fill with Notification PDF" button.',
          'Select the official Govt PDF from your phone.',
          'The AI will magically extract the Exam Name, Advt No, Dates, Fees, and Eligibility in seconds!',
        ],
      ),
      GuideFeature(
        title: '2. The Journey Tracker',
        icon: Icons.map,
        color: Colors.blue,
        description: 'Track your exact progress through complex multi-stage exams.',
        bulletPoints: [
          'When adding an exam, toggle the stages it has (e.g., Mains, Skill Test, Interview).',
          'In the Exam Details page, you will see a beautiful Journey Stepper.',
          'Tap the dropdown next to a stage to mark it as "Admit Card Out", "Exam Given", or "Passed".',
          'If you mark a stage as "Failed" or "Missed", the rest of the journey will grey out.',
        ],
      ),
      GuideFeature(
        title: '3. Live Status AI Search',
        icon: Icons.travel_explore,
        color: Colors.teal,
        description: 'Instantly check the internet for official admit cards or results.',
        bulletPoints: [
          'Go to the Journey Tracker in any Exam Details page.',
          'Find your current active stage (e.g., Prelims).',
          'Tap the "Check Current Status" button.',
          'The app will silently search the web and summarize real-time news about admit card releases or merit lists!',
        ],
      ),
      GuideFeature(
        title: '4. Preparation Hub & Syllabus',
        icon: Icons.menu_book,
        color: Colors.indigo,
        description: 'Get a customized, chapter-wise study plan.',
        bulletPoints: [
          'Scroll to the bottom of an Exam Details page and tap "Generate Study Plan".',
          'Upload the notification PDF.',
          'The AI will combine the PDF and Internet data to build a complete Exam Pattern and Syllabus checklist.',
          'Check off topics as you study to see your Overall Preparation progress bar grow!',
        ],
      ),
      GuideFeature(
        title: '5. Advanced Routine Alarms',
        icon: Icons.alarm,
        color: Colors.orange,
        description: 'Build a strict study routine and never miss a deadline.',
        bulletPoints: [
          'Go to the "Reminders" tab inside any exam to add an alarm.',
          'Set custom rules like: "Every 2 weeks on Mon & Wed, until the Prelims Exam".',
          'Enable "High Priority" if you want the alarm to wake up your phone screen and ring loudly even in sleep mode!',
          'Manage all your alarms globally from the "Master Alarm Hub" in the side menu.',
        ],
      ),
      GuideFeature(
        title: '6. Credentials Vault',
        icon: Icons.lock,
        color: Colors.redAccent,
        description: 'Safely store your login IDs and passwords.',
        bulletPoints: [
          'Save your Registration Number, Roll Number, and Password for each exam.',
          'Passwords are hidden behind an eye icon for security.',
          'Tap the copy icon to instantly copy credentials to your clipboard when logging into portals.',
        ],
      ),
      // NEW FEATURE PLACEHOLDER: Just add a new GuideFeature() here when you build it!
      GuideFeature(
        title: '7. Export to Native Excel',
        icon: Icons.table_view,
        color: Colors.green,
        description: 'Take full control of your data by exporting it to a premium Excel sheet.',
        bulletPoints: [
          'Open the side menu and tap "Export to Excel".',
          'Select the specific timeframe (Years) and columns you want to export.',
          'The generated .xlsx file will have colored statuses, native dropdowns, and calendar date cells!',
        ],
      ),
      GuideFeature(
        title: '8. Cloud Sync & AI Setup',
        icon: Icons.cloud_sync,
        color: Colors.blueGrey,
        description: 'Keep your data permanently safe and 100% free.',
        bulletPoints: [
          'Log in with Google to securely backup your exams and alarms to a hidden folder in your Drive.',
          'Go to "AI Settings" to paste your own Free Cerebras or Groq API key to power all the AI features without any server costs!',
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('How to Use'),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Welcome to Govt Exams Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your all-in-one companion for tracking applications, managing study routines, and automating syllabus extraction with AI.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final feature = features[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: feature.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(feature.icon, color: feature.color),
                        ),
                        title: Text(feature.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
                        children: [
                          Text(feature.description, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 12),
                          ...feature.bulletPoints.map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Expanded(child: Text(point, style: const TextStyle(fontSize: 14, height: 1.4))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                  );
                },
                childCount: features.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}