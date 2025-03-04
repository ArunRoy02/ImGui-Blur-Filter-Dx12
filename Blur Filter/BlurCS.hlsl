//=============================================================================
// Performs a separable Guassian blur with a blur radius up to 5 pixels.
//=============================================================================

cbuffer cbSettings : register(b0)
{
	// We cannot have an array entry in a constant buffer that gets mapped onto
	// root constants, so list each element.  

    int gBlurRadius;
    int2 gBlurStart; // New: Start position for the blur
    
	// Support up to 11 blur weights.
    float w0;
    float w1;
    float w2;
    float w3;
    float w4;
    float w5;
    float w6;
    float w7;
    float w8;
    float w9;
    float w10;
};

static const int gMaxBlurRadius = 5;

Texture2D gInput : register(t1);
RWTexture2D<float4> gOutput : register(u1);

#define N 256
#define CacheSize (N + 2 * gMaxBlurRadius) 
groupshared float4 gCache[CacheSize];

[numthreads(N, 1, 1)]
void HorzBlurCS(int3 groupThreadID : SV_GroupThreadID, int3 dispatchThreadID : SV_DispatchThreadID)
{
    float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

    int2 pixelCoord = dispatchThreadID.xy + gBlurStart;
    
    if (groupThreadID.x < gBlurRadius)
    {
        int x = max(pixelCoord.x - gBlurRadius, 0);
        gCache[groupThreadID.x] = gInput[int2(x, pixelCoord.y)];
    }
    
    if (groupThreadID.x >= N - gBlurRadius)
    {
        int x = min(pixelCoord.x + gBlurRadius, gInput.Length.x - 1);
        gCache[groupThreadID.x + 2 * gBlurRadius] = gInput[int2(x, pixelCoord.y)];
    }
    
    gCache[groupThreadID.x + gBlurRadius] = gInput[min(pixelCoord.xy, gInput.Length.xy - 1)];

    // Wait for all threads to complete loading to shared memory
    GroupMemoryBarrierWithGroupSync();

    float4 blurColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
    {
        int k = groupThreadID.x + gBlurRadius + i;
        blurColor += weights[i + gBlurRadius] * gCache[k];
    }

    gOutput[pixelCoord.xy] = blurColor;
}

[numthreads(1, N, 1)]
void VertBlurCS(int3 groupThreadID : SV_GroupThreadID, int3 dispatchThreadID : SV_DispatchThreadID)
{
    float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

    int2 pixelCoord = dispatchThreadID.xy + gBlurStart;
   
    if (groupThreadID.y < gBlurRadius)
    {
        int y = max(pixelCoord.y - gBlurRadius, 0);
        gCache[groupThreadID.y] = gInput[int2(pixelCoord.x, y)];
    }
    
    if (groupThreadID.y >= N - gBlurRadius)
    {
        int y = min(pixelCoord.y + gBlurRadius, gInput.Length.y - 1);
        gCache[groupThreadID.y + 2 * gBlurRadius] = gInput[int2(pixelCoord.x, y)];
    }
    
    gCache[groupThreadID.y + gBlurRadius] = gInput[min(pixelCoord.xy, gInput.Length.xy - 1)];

    // Wait for all threads to complete loading to shared memory
    GroupMemoryBarrierWithGroupSync();

    float4 blurColor = float4(0, 0, 0, 0);
    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
    {
        int k = groupThreadID.y + gBlurRadius + i;
        blurColor += weights[i + gBlurRadius] * gCache[k];
    }

    gOutput[pixelCoord.xy] = blurColor;
}

//float4 ConvertR10G10B10A2ToR8G8B8A8(uint inputPixel)
//{
//    uint r10 = inputPixel & 0x3FF;
//    uint g10 = (inputPixel >> 10) & 0x3FF;
//    uint b10 = (inputPixel >> 20) & 0x3FF;
//    uint a2 = (inputPixel >> 30) & 0x3;

//    float4 outputPixel;
//    outputPixel.r = (r10 / 1023.0f);
//    outputPixel.g = (g10 / 1023.0f);
//    outputPixel.b = (b10 / 1023.0f);
//    outputPixel.a = (a2 / 3.0f);

//    // Normalize to [0, 255]
//    outputPixel = outputPixel * 255.0f;

//    // Convert to 8-bit
//    outputPixel = round(outputPixel);
//    outputPixel = outputPixel / 255.0f; // Normalize back to [0, 1] for GPU processing

//    return outputPixel;
//}

//[numthreads(N, 1, 1)]
//void HorzBlurCS(int3 groupThreadID : SV_GroupThreadID, int3 dispatchThreadID : SV_DispatchThreadID)
//{
//    float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

//    int2 pixelCoord = dispatchThreadID.xy + gBlurStart;
//    uint inputPixel = gInput.Load(int3(pixelCoord, 0));

//    float4 inputColor = asfloat(inputPixel);
//    if (gConvertFormat == 1)
//    {
//        inputColor = ConvertR10G10B10A2ToR8G8B8A8(inputPixel);
//    }

//    if (groupThreadID.x < gBlurRadius)
//    {
//        int x = max(pixelCoord.x - gBlurRadius, 0);
//        gCache[groupThreadID.x] = gInput[int2(x, pixelCoord.y)];
//    }

//    if (groupThreadID.x >= N - gBlurRadius)
//    {
//        int x = min(pixelCoord.x + gBlurRadius, gInput.Length.x - 1);
//        gCache[groupThreadID.x + 2 * gBlurRadius] = gInput[int2(x, pixelCoord.y)];
//    }

//    gCache[groupThreadID.x + gBlurRadius] = gInput[min(pixelCoord.xy, gInput.Length.xy - 1)];

//    // Wait for all threads to complete loading to shared memory
//    GroupMemoryBarrierWithGroupSync();

//    float4 blurColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
//    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
//    {
//        int k = groupThreadID.x + gBlurRadius + i;
//        blurColor += weights[i + gBlurRadius] * gCache[k];
//    }

//    gOutput[pixelCoord.xy] = blurColor;
//}

//[numthreads(1, N, 1)]
//void VertBlurCS(int3 groupThreadID : SV_GroupThreadID, int3 dispatchThreadID : SV_DispatchThreadID)
//{
//    float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };

//    int2 pixelCoord = dispatchThreadID.xy + gBlurStart;
//    uint inputPixel = gInput.Load(int3(pixelCoord, 0));

//    float4 inputColor = asfloat(inputPixel);
//    if (gConvertFormat == 1)
//    {
//        inputColor = ConvertR10G10B10A2ToR8G8B8A8(inputPixel);
//    }

//    if (groupThreadID.y < gBlurRadius)
//    {
//        int y = max(pixelCoord.y - gBlurRadius, 0);
//        gCache[groupThreadID.y] = gInput[int2(pixelCoord.x, y)];
//    }

//    if (groupThreadID.y >= N - gBlurRadius)
//    {
//        int y = min(pixelCoord.y + gBlurRadius, gInput.Length.y - 1);
//        gCache[groupThreadID.y + 2 * gBlurRadius] = gInput[int2(pixelCoord.x, y)];
//    }

//    gCache[groupThreadID.y + gBlurRadius] = gInput[min(pixelCoord.xy, gInput.Length.xy - 1)];

//    // Wait for all threads to complete loading to shared memory
//    GroupMemoryBarrierWithGroupSync();

//    float4 blurColor = float4(0, 0, 0, 0);
//    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
//    {
//        int k = groupThreadID.y + gBlurRadius + i;
//        blurColor += weights[i + gBlurRadius] * gCache[k];
//    }

//    gOutput[pixelCoord.xy] = blurColor;
//}
