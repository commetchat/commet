export BUILD_NUMBER=`git rev-list --count main`
perl -i -pe 's/^(version:\s+\d+\.\d+\.\d+\+)(\d+)$/$1.$ENV{BUILD_NUMBER}/e' pubspec.yaml