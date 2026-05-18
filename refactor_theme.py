import os
import re

def process_dart_files(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                # Remove const keyword before constructors that use dynamic getters
                # This regex finds 'const ' followed by one of these Widget/Class names and removes the 'const '
                classes_to_unconst = [
                    'Icon', 'TextStyle', 'Divider', 'BorderSide', 'BoxDecoration',
                    'LinearGradient', 'IconThemeData', 'Text', 'Center', 'Padding',
                    'Row', 'Column', 'Container', 'SizedBox', 'Expanded', 'Positioned',
                    'Stack', 'CircleAvatar', 'TextButton', 'OutlinedButton',
                    'ElevatedButton', 'AppBarTheme', 'InputDecorationTheme',
                    'ElevatedButtonThemeData', 'SystemUiOverlayStyle', 'ThemeData',
                    'BorderRadius', 'Border', 'BoxShadow', 'StatItem', 'AppBadge'
                ]
                
                pattern = r'const\s+(' + '|'.join(classes_to_unconst) + r')\('
                
                # We can't know for sure if it contains a dynamic color inside its body,
                # but removing 'const' is generally safe in Flutter (just loses a tiny optimization).
                # To be safer, we will just remove all 'const' before these classes globally.
                content = re.sub(pattern, r'\1(', content)

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)

if __name__ == "__main__":
    process_dart_files("d:\\Proyek 2\\sanggar_mobile\\lib")
    print("Refactoring complete.")
