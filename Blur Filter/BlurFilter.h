#pragma once

#include <cassert>
#include <mutex>
#include <unordered_map>

#include "d3d12.h"
#include "d3dx12.h"

#include <dxgi1_4.h>
#pragma comment(lib, "dxgi.lib")

#include "imgui.h"

enum ShaderBlob
{
    HorzBlurCS = 0,
    VertBlurCS
};

enum PipelineStates
{
    HorzBlurPso = 0,
    VertBlurPso
};

class BlurFilter
{
public:
    BlurFilter ( ID3D12Device* device, ID3D12DescriptorHeap* pSrvHeap, UINT Width, UINT Height, DXGI_FORMAT Format, int descHandleIndex );
    BlurFilter ( const BlurFilter& rhs ) = delete;
    BlurFilter& operator=( const BlurFilter& rhs ) = delete;
    ~BlurFilter ( ) = default;

    ID3D12Resource* Output ( );
    void BuildResources ( );
    void BuildDescriptors (
        CD3DX12_CPU_DESCRIPTOR_HANDLE hCpuDescriptor,
        CD3DX12_GPU_DESCRIPTOR_HANDLE hGpuDescriptor,
        UINT descriptorSize );
    void BuildDescriptors ( );

    void AllocateDescriptors ( );
    void InitializeComputeRootSignature ( );
    void InitializeBlurPSO ( );

    void OnResize ( ImVec2 position, ImVec2 region );

    D3D12_BOX GetTargetBox ( );
    bool IsTargetOutOfBounds ( ID3D12Resource* pTargetTexture, D3D12_BOX srcBox );

    void GetBackBufferResource ( IDXGISwapChain3* swapChain, UINT bufferIndex = 0 );
    void Execute ( ID3D12GraphicsCommandList* cmdList, ID3D12Resource*, int blurCount );

    void CleanupBackBuffer ( );
    void CleanupBlurMap ( );

    bool mWindowResized = false;

private:
    const float mSigma = 2.5f;

    int mBlurDescriptorHandleIndex = 3;

    ID3D12Device* md3dDevice = nullptr;
    ID3D12DescriptorHeap* md3dSrvHeap = nullptr;
    IDXGISwapChain3* mSwapChain = nullptr;

    ID3D12RootSignature* mComputeRootSignature = nullptr;

    std::unordered_map<ShaderBlob, ID3DBlob*> mShaders;
    std::unordered_map<PipelineStates, ID3D12PipelineState*> mPSOs;

    UINT mTextureWidth = 0;
    UINT mTextureHeight = 0;

    UINT mBlurPosX = 0;
    UINT mBlurPosY = 0;
    UINT mBlurRegionWidth = 0;
    UINT mBlurRegionHeight = 0;

    DXGI_FORMAT mFormat = DXGI_FORMAT_R8G8B8A8_UNORM;

    CD3DX12_CPU_DESCRIPTOR_HANDLE mBlur0CpuSrv;
    CD3DX12_CPU_DESCRIPTOR_HANDLE mBlur0CpuUav;

    CD3DX12_CPU_DESCRIPTOR_HANDLE mBlur1CpuSrv;
    CD3DX12_CPU_DESCRIPTOR_HANDLE mBlur1CpuUav;

    CD3DX12_GPU_DESCRIPTOR_HANDLE mBlur0GpuSrv;
    CD3DX12_GPU_DESCRIPTOR_HANDLE mBlur0GpuUav;

    CD3DX12_GPU_DESCRIPTOR_HANDLE mBlur1GpuSrv;
    CD3DX12_GPU_DESCRIPTOR_HANDLE mBlur1GpuUav;

    // BackBuffer Resource
    ID3D12Resource* mBackBuffer = nullptr;

    // Two for ping-ponging the blur textures.
    ID3D12Resource* mBlurMap0 = nullptr;
    ID3D12Resource* mBlurMap1 = nullptr;
};

struct CBSettings
{
    int gBlurRadius;
    int gBlurStart[2];
    float weights[11];

    static std::vector<float> CalcGaussWeights ( float sigma );

    CBSettings ( float weight, int x, int y )
    {
        auto weightsVec = CalcGaussWeights ( weight );
        gBlurRadius = static_cast< int >(weightsVec.size ( )) / 2;

        gBlurStart[0] = x;
        gBlurStart[1] = y;

        std::copy ( weightsVec.begin ( ), weightsVec.end ( ), weights );
    }
};