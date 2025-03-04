# ImGui Blur DirectX 12

This repository presents a Gaussian Blur Filter tailored for DirectX 12 applications, specifically enhancing ImGui interfaces. The filter facilitates the integration of background blur effects into ImGui windows or any DirectX 12 project, leveraging compute shaders for optimal performance and simplicity. Its design as a standalone library ensures seamless integration across diverse DirectX 12 environments, with compatibility spanning various DXGI_FORMAT color spaces to accommodate different render target configurations. Microsoft's sample projects for Gaussian blur are annoyingly convoluted and overengineered, so I created this to provide a cleaner, more practical solution.

https://github.com/user-attachments/assets/6bfcc1da-dbbd-4c70-bf69-3f72c373568a

## Features

- **Compute Shader Implementation**: Utilizes compute shaders to apply Gaussian blur, eliminating the necessity to modify existing pixel or vertex shaders.
- **Standalone Library**: Architected for straightforward integration into existing DirectX 12 projects without extensive refactoring.
- **Broad Format Support**: Compatible with multiple DXGI_FORMAT color spaces, ensuring adaptability to various render target setups.

## Integration Guide

### 1. Initialization

Post the creation of the DirectX 12 device, initialize the blur filter:

```cpp
g_pBlurFilter = std::make_unique<BlurFilter>(
    g_pd3dDevice,
    g_pd3dSrvDescHeap,
    swapDesc.BufferDesc.Width,
    swapDesc.BufferDesc.Height,
    swapDesc.BufferDesc.Format,
    DescriptorCount::Blur
);
```

### 2. Constant Buffer Update

Within the `ImGui::Begin` and `ImGui::End` routines, update the constant buffers to apply the blur effect to the desired ImGui window:

```cpp
ImGui::Begin("Hello, world!");

// ...

// Apply background blur to this window and handle resizes
if (g_pBlurFilter != nullptr)
    g_pBlurFilter->OnResize(ImGui::GetWindowPos(), ImGui::GetWindowSize());

// ...

ImGui::End();
```

### 3. Backbuffer Acquisition and Blur Execution

Retrieve the backbuffer and execute the blur passes (e.g., applying it to the night sky background image in this example) prior to rendering ImGui draw data. Ability to control number of blur passes with nBlurCount.

```cpp
// Additional rendering setup...

g_pBlurFilter->GetBackBufferResource(g_pSwapChain, backBufferIdx);
g_pBlurFilter->Execute(g_pd3dCommandList, pCurrentRenderTargetResource, nBlurCount);

// Render ImGui on top
ImGui_ImplDX12_RenderDrawData(ImGui::GetDrawData(), g_pd3dCommandList);

// Additional rendering teardown...
```

### 4. Resource Cleanup on Resize

In scenarios where the application window is resized or the device undergoes a reset, reinitialize the blur filter after cleaning up previous states:

```cpp
if (g_pBlurFilter)
{
    g_pBlurFilter->CleanupBackBuffer();
    g_pBlurFilter->CleanupBlurMap();
}
```

## Known Limitations

- **Single Window Blur Support**: Currently, the implementation supports background blur for only one ImGui window at a time. Extending support to multiple windows would necessitate modifications to the shader's constant buffers, potentially incorporating an array of window regions to blur.

## Future Enhancements

- **Multi-Window Blur Support**: Implementing the capability to apply background blur across multiple ImGui windows concurrently.
- **Performance Optimization**: Refining the compute shader and resource management to further enhance performance.

For comprehensive integration instructions and advanced configurations, please refer to the detailed documentation within the repository.
