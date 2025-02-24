# MarmotApp

## Run with Limited Memory on Host
* Create a new group for limited-memory case.
```bash
sudo cgcreate -g memory:/limmem
```

* Set the limits in bytes.
Limit 2GB memory.
```bash
sudo echo 2147483648 | sudo tee /sys/fs/cgroup/limmem/memory.max
```

* Clear page cache.
```bash
sudo sh -c 'echo 1 >  /proc/sys/vm/drop_caches'
```

* Run the program with limited memory.
```bash
sudo cgexec -g memory:limmem ./llama-cli -m ggml-model-llama-2-70b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 16
sudo cgexec -g memory:limmem ./llama-cli-prefetch -m ggml-model-llama-2-70b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 16 -am 2.0 -tp 1
```

```bash
./llama-cli -m hf-models/ggml-model-llama-2-7b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 128
./llama-cli-prefetch -m hf-models/ggml-model-llama-2-7b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 128 -am 2 -tp 1 -t 1
```

## Compile and Run for Android
* Compile.
```bash
cmake -DCMAKE_TOOLCHAIN_FILE=android-ndk-r27/build/cmake/android.toolchain.cmake -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-32 -DCMAKE_C_FLAGS="-march=armv8.7a" -DCMAKE_CXX_FLAGS="-march=armv8.7a" -DGGML_OPENMP=OFF -DGGML_LLAMAFILE=OFF -B build-android
cmake --build build-android --config Release -j
cmake --install build-android --prefix android --config Release
```

* Run.
```bash
LD_LIBRARY_PATH=android/lib/ ./android/bin/llama-cli -m models/ggml-model-llama-2-7b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 128
LD_LIBRARY_PATH=android/lib/ ./android/bin/llama-cli-prefetch -m models/ggml-model-llama-2-7b-chat-q4_0.gguf -p "I believe the meaning of life is" -n 128 -am 2 -tp 1 -t 1
```