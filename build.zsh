cd "$(dirname "$0")"
cd ./

set -eu

clang++ -std=c++20 -Wc++20-extensions -fobjc-arc -O3 \
-framework Cocoa \
-I ./ \
-I./eigen/3.4.0_1/include/eigen3 \
./tridecimator.mm \
./wrap/ply/plylib.cpp \
-o ./tridecimator