#! /bin/bash
echo "Running all tests"
cd ~/Projects
rm -f ~/Projects/test_all.log
for repo in $(ls -d */); do
    cd $repo
    echo "Testing $repo"
    if [ -d "tests" ]; then
        pytest |& tee -a ~/Projects/test_all.log
    fi
    cd ..
done
echo "Done"

