/*=============================================================================
	ReShade 4 effect file
    github.com/aestheticses/shaders-reshade

    by owner of aestheticses@gmail.com
=============================================================================*/

/*=============================================================================
	Preprocessor settings
=============================================================================*/

	uniform float2 MouseCoords < source = "mousepoint"; >;

/*=============================================================================
	UI Uniforms
=============================================================================*/

uniform float BlurAmount <
    ui_type = "slider";
    ui_min = 0.3;
    ui_max = 2.0;
    ui_label = "Blur Amount";
> = 1;

uniform float QualityOfBlur <
    ui_type = "slider";
    ui_min = 0.2;
    ui_max = 1.8;
    ui_label = "Quality Of Blur";
> = 1;

uniform float MinMouseSpeed <
    ui_type = "slider";
    ui_min = 0;
    ui_max = 5;
    ui_label = "Min Mouse Speed";
    ui_tooltip = "The Minimum Speed of Mouse to Calculate Blur";
> = 0.3;

uniform float SmoothSpeed <
    ui_type = "slider";
    ui_min = 0.2;
    ui_max = 0.9;
    ui_label = "Smooth Moving";
> = 0.6;

uniform float HorizonY <
    ui_type = "slider";
    ui_min = 0.2;
    ui_max = 0.5;
    ui_label = "usual Height of Horizon";
    ui_tooltip = "Distance from Up Boundary of Screen";
> = 0.3;

uniform float depthfadestart <
    ui_type = "slider";
    ui_min = -0.9;
    ui_max = 1.0;
    ui_label = "depth fade start";
    ui_tooltip = "Distance from Up Boundary of Screen";
> = 0.95;

uniform bool  EyeForecasting <
    ui_type = "bool";
    ui_label = "Enable Eye-Forecasting";
    ui_tooltip = "When mouse is moving left, Less Blur appears on left.";
> = true;

uniform bool  MaskUI <
    ui_type = "bool";
    ui_label = "Try to unmask UI";
    ui_tooltip = "choose ON when play Asassin's Creed Odyssey";
> = false;

/*=============================================================================
	Textures, Samplers, Globals
=============================================================================*/

#include "ReShade.fxh"


texture2D MMBR_MBlurTex 	    { Width = 1;   Height = 1;   Format = RGBA16f; };
texture2D MMBR_MBlurTexPrev     { Width = 1;   Height = 1;   Format = RGBA16f; };//{ Format = R16F; };

sampler2D sMMBR_MBlurTex	    { Texture = MMBR_MBlurTex; };
sampler2D sMMBR_MBlurTexPrev	{ Texture = MMBR_MBlurTexPrev; };

texture2D MBCommonTex0 	{ Width = BUFFER_WIDTH;   Height = BUFFER_HEIGHT;   Format = RGBA8; MipLevels = 2;};
sampler2D sMBCommonTex0	{ Texture = MBCommonTex0;	};

/*=============================================================================
	Functions
=============================================================================*/



/*=============================================================================
	Vertex Shader
=============================================================================*/

struct MMBR_VSOUT
{
	float4   vpos           : SV_Position;
    float4   txcoord        : TEXCOORD0;
    //float4   offset0        : TEXCOORD1;
    //float2x2 offsmat        : TEXCOORD2;

};

MMBR_VSOUT VS_MMBR(in uint id : SV_VertexID)
{
    MMBR_VSOUT OUT;

    OUT.txcoord.x = (id == 2) ? 2.0 : 0.0;
    OUT.txcoord.y = (id == 1) ? 2.0 : 0.0;
    OUT.txcoord.zw = OUT.txcoord.xy ;
    OUT.vpos = float4(OUT.txcoord.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

    return OUT;
}

/*=============================================================================
	Functions
=============================================================================*/




/*=============================================================================
	Pixel Shaders
=============================================================================*/

void PS_CopyBackBuffer(in MMBR_VSOUT IN, out float4 color : SV_Target0)
{
    color = tex2D(ReShade::BackBuffer, IN.txcoord.xy);
}

void PS_ReadMBlur(in MMBR_VSOUT IN, out float4 VMouse : SV_Target0, out float4 color : SV_Target1, out float4 depth : SV_Target2)
{
    VMouse.zw = min(max(float2(BUFFER_WIDTH*0.01,BUFFER_HEIGHT*0.01),MouseCoords),float2(BUFFER_WIDTH*0.99,BUFFER_HEIGHT*0.99));
 
	float2 VMousexy=(tex2D(sMMBR_MBlurTexPrev, 1).zw - VMouse.zw)/18*BlurAmount;
    float2 VMousexypre=tex2D(sMMBR_MBlurTexPrev, 0.5).xy;
    
    
//try to adjust a game that always reset mouse-position.
	float2 if00=VMouse.zw-float2(BUFFER_WIDTH/2,BUFFER_HEIGHT/2);
    float distrct0=(BUFFER_HEIGHT+BUFFER_WIDTH)*0.0002;

	if (if00.x > 0-distrct0 && if00.x < distrct0 && if00.y > 0-distrct0 && if00.y < distrct0) VMousexy=VMousexypre*0.7;

	 VMouse.xy = lerp(VMousexy,VMousexypre,SmoothSpeed);
	
    color=tex2D(ReShade::BackBuffer, IN.txcoord.xy);
    
	depth = ReShade::GetLinearizedDepth(IN.txcoord.xy) * RESHADE_DEPTH_LINEARIZATION_FAR_PLANE;
}

void PS_CopyMBlur(in MMBR_VSOUT IN, out float4 VMouse : SV_Target0)
{
    VMouse = tex2D(sMMBR_MBlurTex,1);
}

void PS_MotionBlurEFC(in MMBR_VSOUT IN, out float4 color : SV_Target0)
{

    float nmaskui = 0;
    if (MaskUI) nmaskui = 1.1;
	float4 centerTap = tex2D(sMBCommonTex0, IN.txcoord.xy);

	float4 mouseV = tex2D(sMMBR_MBlurTex, 1)/QualityOfBlur;
	float  ivo=sqrt(dot(mouseV.xy,mouseV.xy));
	float  iv= 15*sin(min(ivo*2,1.5708))* QualityOfBlur;
	
	float depth = saturate(log(ReShade::GetLinearizedDepth(IN.txcoord.xy)*10+depthfadestart) ) ;
	
		 float stx =IN.txcoord.x-0.5;
 		float sty =(IN.txcoord.y-HorizonY);
 		float nearblur=saturate(0.5*(abs(stx)-0.12));
	depth = lerp(depth,1.0,nearblur) * saturate(1-centerTap.a*nmaskui);
	//(1-centerTap.a) only work with Assassins Creed Odyssey

	float nSteps 		= iv /rsqrt(max(depth-0.02,0))-MinMouseSpeed ;
	float expCoeff 		= -2.0 / (nSteps * nSteps + 1e-3); 


	float4 gaussianSum = 0.0;
	float  gaussianSumWeight = 1e-5;

	float4 stepV;
 		stepV.xy = mouseV.xy *rsqrt(ivo+8)   / 400 ;
 		
 		float efcMouseSpeed=0.2*sin(max(min(mouseV.x*1.5,1.5708),-1.5708));
		 
		if (EyeForecasting)
		stepV *= saturate(abs(stx+efcMouseSpeed)*1.5+abs(sty)*2+0.1);
		else stepV *= saturate(abs(stx)*3+abs(sty)*2+0.4);
		
 		
 		
 		
 		//stepV.x = stepV.x *(1 / pow( cos(stx),2) );
 		stepV.x = stepV.x *(1.4*pow(stx,4) + 0.7*stx*stx +1)  + stx*stepV.y *(0.8*pow(sty,5)+0.8*pow(sty,3)+sty)*2;
 		
 		stepV.y = stepV.y *(1.4*pow(sty,4) + 0.7*sty*sty +1)  + sty*stepV.x *(0.8*pow(stx,5)+0.8*pow(stx,3)+stx)*4;

	for(float iStep = -nSteps-0.7; iStep <= nSteps*1.2; iStep++)
	{
		float currentWeight = exp((iStep+nSteps/2) * iStep * expCoeff);
		float currentOffset = 2.0 * iStep - 0.5; //Sample between texels to double blur width at no cost
		float2 currentxy = IN.txcoord.xy + stepV.xy * currentOffset;
		
		float4 currentTap = tex2Dlod(sMBCommonTex0, float4(currentxy,0,0));
		
		currentWeight *= (0.055 + max(currentTap.r+currentTap.g+currentTap.b-2.4,0))* saturate(1-currentTap.a*nmaskui); 
		//(1-currentTap.a) only work with Assassins Creed Odyssey
		float depthweight = saturate(log(ReShade::GetLinearizedDepth(currentxy)*10+depthfadestart));
		currentWeight *= lerp(depthweight,1.0,nearblur);
		if (EyeForecasting)
		currentWeight *= saturate(abs(currentxy.x-0.5+efcMouseSpeed)+abs(currentxy.y-HorizonY)+0.1);
		
		gaussianSum += currentTap * currentWeight;
		gaussianSumWeight += currentWeight;
	}

	gaussianSum /= gaussianSumWeight;

	color.rgb = lerp(centerTap.rgb, gaussianSum.rgb, saturate(gaussianSumWeight/(0.003+gaussianSumWeight)));
    color.a = centerTap.a;
}

/*=============================================================================
	Techniques
=============================================================================*/

technique MouseMotionBlur
< ui_tooltip = "                         >> MMBR V1.1<<\n\n"
               "MMBR is a shader which can blurs moving things.\n"
               "totally based on mouse moving, it didn't effects on moving that caused by runing(WASD).\n";
               >
{

     pass
    {
        VertexShader = VS_MMBR;
        PixelShader = PS_CopyBackBuffer;
        RenderTarget = MBCommonTex0;
    }
    pass
    {
        VertexShader = VS_MMBR;
        PixelShader = PS_ReadMBlur;
        RenderTarget = MMBR_MBlurTex;
    }
    pass
    {
        VertexShader = VS_MMBR;
        PixelShader = PS_CopyMBlur;
        RenderTarget = MMBR_MBlurTexPrev;
    }

    pass
    {
        VertexShader = VS_MMBR;
        PixelShader  = PS_MotionBlurEFC;
    }

}
