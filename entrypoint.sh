#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

download_if_missing() {
    local url="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        echo "Model exists, skipping: $dest"
        return
    fi

    echo "Downloading model: $dest"
    mkdir -p "$(dirname "$dest")"
    wget -q --show-progress "$url" -O "$dest"
    echo "Download complete: $dest"
}

echo "Checking required model files..."
download_if_missing "https://huggingface.co/mig1234/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors" "/ComfyUI/models/diffusion_models/Wan2_2-I2V-A14B-HIGH_fp8_e4m3fn_scaled_KJ.safetensors"
download_if_missing "https://huggingface.co/mig1234/WanVideo_comfy_fp8_scaled/resolve/main/I2V/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors" "/ComfyUI/models/diffusion_models/Wan2_2-I2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors"
download_if_missing "https://huggingface.co/mig1234/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors" "/ComfyUI/models/loras/high_noise_model.safetensors"
download_if_missing "https://huggingface.co/mig1234/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors" "/ComfyUI/models/loras/low_noise_model.safetensors"
download_if_missing "https://huggingface.co/mig1234/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" "/ComfyUI/models/clip_vision/clip_vision_h.safetensors"
download_if_missing "https://huggingface.co/mig1234/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" "/ComfyUI/models/text_encoders/umt5-xxl-enc-bf16.safetensors"
download_if_missing "https://huggingface.co/mig1234/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" "/ComfyUI/models/vae/Wan2_1_VAE_bf16.safetensors"

# Start ComfyUI in the background
echo "Starting ComfyUI in the background..."
python /ComfyUI/main.py --listen --use-sage-attention &

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
max_wait=120  # 최대 2분 대기
wait_count=0
while [ $wait_count -lt $max_wait ]; do
    if curl -s http://127.0.0.1:8188/ > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    echo "Waiting for ComfyUI... ($wait_count/$max_wait)"
    sleep 2
    wait_count=$((wait_count + 2))
done

if [ $wait_count -ge $max_wait ]; then
    echo "Error: ComfyUI failed to start within $max_wait seconds"
    exit 1
fi

# Start the handler in the foreground
# 이 스크립트가 컨테이너의 메인 프로세스가 됩니다.
echo "Starting the handler..."
exec python handler.py