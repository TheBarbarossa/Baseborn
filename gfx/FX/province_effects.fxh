Includes = {
	"cw/pdxterrain.fxh"
	"jomini/jomini_province_overlays.fxh"
	"province_effects_variables.fxh"
}

struct EffectIntensities
{
	float _Drought;
	float _Flood;
	float _Summer;
	float _Snow;
	float _Autumn;
	float _DryAutumn;
	float _WetAutumn;
	float _SnowNew;
};

PixelShader =
{
	TextureSampler ProvinceEffectsNoise
	{
		Index = 14
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
		File = "gfx/map/textures/wavy_noise.dds"
	}

	BufferTexture ProvinceEffectDataBuffer
	{
		Ref = ProvinceEffectData
		type = float4
	}

	Code
	[[
		// Enable to debug mask
		// #define DEBUG_PROVINCE_EFFECT_MASK_DROUGHT
		// #define DEBUG_PROVINCE_EFFECT_MASK_FLOOD
		// #define DEBUG_PROVINCE_EFFECT_MASK_SUMMER
		// #define DEBUG_PROVINCE_EFFECT_MASK_SNOW
		// #define DEBUG_PROVINCE_EFFECT_MASK_SNOWNEW

		static const float3 UP_VECTOR = float3( 0.0f, 1.0f, 0.0f );
		static const float SKIP_VALUE = 0.001f;

		void DebugCondition( inout float3 Diffuse, EffectIntensities ConditionData )
		{
			#if defined( DEBUG_PROVINCE_EFFECT_MASK_DROUGHT )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 1.0f, 0.0f, 0.0f ), ConditionData._Drought );
			#endif

			#if defined( DEBUG_PROVINCE_EFFECT_MASK_FLOOD )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 0.0f, 1.0f, 0.0f ), ConditionData._Flood );
			#endif

			#if defined( DEBUG_PROVINCE_EFFECT_MASK_SUMMER )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 0.0f, 0.0f, 1.0f ), ConditionData._Summer );
			#endif

			#if defined( DEBUG_PROVINCE_EFFECT_MASK_SNOW )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 1.0f, 1.0f, 0.0f ), ConditionData._Snow );
			#endif			
			#if defined( DEBUG_PROVINCE_EFFECT_MASK_SNOWNEW )
				Diffuse.rgb = lerp( Diffuse.rgb, float3( 1.0f, 1.0f, 0.0f ), ConditionData._SnowNew );
			#endif
		}

		float3 AdjustHsv( float3 Rgb, float Hue, float Saturation, float Value )
		{
			float3 Color = RGBtoHSV( Rgb );
			Color.x += Hue;
			Color.y *= Saturation;
			Color.z *= Value;
			return HSVtoRGB( Color );
		}

		float3 AdjustSaturation( float3 Rgb, float Saturation )
		{
			return AdjustHsv( Rgb, 0.0f, Saturation, 1.0f );
		}

		float4 SampleProvinceEffects( float2 MapCoords )
		{
			float2 ColorIndex = PdxTex2D( ProvinceColorIndirectionTexture, MapCoords ).rg;
			int Index = ColorIndex.x * 255.0f + ColorIndex.y * 255.0f * 256.0f;
			return PdxReadBuffer4( ProvinceEffectDataBuffer, Index );
		}

		void BilinearSampleProvinceEffectsMask( float2 MapCoords, inout EffectIntensities ConditionData )
		{
			//SEASONS MODDED
			#ifdef LOW_SPEC_SHADERS
				ConditionData._Drought = 0.0f;
				ConditionData._Flood = 0.0f;
				ConditionData._Summer = 0.0f;
				ConditionData._Snow = 0.0f;
				//ConditionData._Autumn = 0.0f;
				//ConditionData._DryAutumn = 0.0f;
				//ConditionData._WetAutumn = 0.0f;
				//ConditionData._SnowNew = 0.0f;
				return;
			#endif
			//END MOD SEASONS
			// ProvinceEffects mask
			float2 Pixel = MapCoords * IndirectionMapSize + 0.5f;
			float2 FracCoord = frac( Pixel );
			Pixel = floor( Pixel ) / IndirectionMapSize - InvIndirectionMapSize / 2.0f;
			float4 C11 = SampleProvinceEffects( Pixel );
			float4 C21 = SampleProvinceEffects( Pixel + float2( InvIndirectionMapSize.x, 0.0f ) );
			float4 C12 = SampleProvinceEffects( Pixel + float2( 0.0f, InvIndirectionMapSize.y ) );
			float4 C22 = SampleProvinceEffects( Pixel + InvIndirectionMapSize );

			// Bilinear interpolation
			float x1 = lerp( C11.g, C21.g, FracCoord.x );
			float x2 = lerp( C12.g, C22.g, FracCoord.x );

			// Opacity
			float ImpactTemp = lerp( x1, x2, FracCoord.y );
			float Impact = RemapClamped( ImpactTemp, 0.0f, OpacityLowImpactValue, 0.0f, 0.5f );
			Impact += RemapClamped( ImpactTemp, OpacityLowImpactValue, OpacityHighImpactValue, 0.0f, 0.5f );

			// ProvinceEffects condition filtering
			float Dro1 = lerp( C11.r == DROUGHT_INDEX, C21.r == DROUGHT_INDEX, FracCoord.x );
			float Dro2 = lerp( C12.r == DROUGHT_INDEX, C22.r == DROUGHT_INDEX, FracCoord.x );
			ConditionData._Drought = lerp( Dro1, Dro2, FracCoord.y ) * Impact;

			float Flo1 = lerp( C11.r == FLOOD_INDEX, C21.r == FLOOD_INDEX, FracCoord.x );
			float Flo2 = lerp( C12.r == FLOOD_INDEX, C22.r == FLOOD_INDEX, FracCoord.x );
			ConditionData._Flood = lerp( Flo1, Flo2, FracCoord.y ) * Impact;

			float Sum1 = lerp( C11.r == SUMMER_INDEX, C21.r == SUMMER_INDEX, FracCoord.x );
			float Sum2 = lerp( C12.r == SUMMER_INDEX, C22.r == SUMMER_INDEX, FracCoord.x );
			ConditionData._Summer = lerp( Sum1, Sum2, FracCoord.y ) * Impact;

			float Snow1 = lerp( C11.r == SNOW_INDEX, C21.r == SNOW_INDEX, FracCoord.x );
			float Snow2 = lerp( C12.r == SNOW_INDEX, C22.r == SNOW_INDEX, FracCoord.x );
			ConditionData._Snow = lerp( Snow1, Snow2, FracCoord.y ) * Impact;
			//Seasons Added
			
			//normal autumn
			float Autumn1 = lerp( C11.r == AUTUMN_INDEX, C21.r == AUTUMN_INDEX, FracCoord.x );
			float Autumn2 = lerp( C12.r == AUTUMN_INDEX, C22.r == AUTUMN_INDEX, FracCoord.x );
			ConditionData._Autumn = lerp( Autumn1, Autumn2, FracCoord.y ) * Impact;
			//dry autumn
			float DryAutumn1 = lerp( C11.r == DRY_AUTUMN_INDEX, C21.r == DRY_AUTUMN_INDEX, FracCoord.x );
			float DryAutumn2 = lerp( C12.r == DRY_AUTUMN_INDEX, C22.r == DRY_AUTUMN_INDEX, FracCoord.x );
			ConditionData._DryAutumn = lerp( DryAutumn1, DryAutumn2, FracCoord.y ) * Impact;
			//wet autumn
			float WetAutumn1 = lerp( C11.r == WET_AUTUMN_INDEX, C21.r == WET_AUTUMN_INDEX, FracCoord.x );
			float WetAutumn2 = lerp( C12.r == WET_AUTUMN_INDEX, C22.r == WET_AUTUMN_INDEX, FracCoord.x );
			ConditionData._WetAutumn = lerp( WetAutumn1, WetAutumn2, FracCoord.y ) * Impact;			
			
			float Snow3 = lerp( C11.r == SNOWNEW_INDEX, C21.r == SNOWNEW_INDEX, FracCoord.x );
			float Snow4 = lerp( C12.r == SNOWNEW_INDEX, C22.r == SNOWNEW_INDEX, FracCoord.x );
			ConditionData._SnowNew = lerp( Snow3, Snow4, FracCoord.y ) * Impact;
			
			
			//End Seasons Added
		}
		
		void SampleProvinceEffectsMask( float2 MapCoords, inout EffectIntensities ConditionData )
		{
			//SEASONS MODDED
			#ifdef LOW_SPEC_SHADERS
				ConditionData._Drought = 0.0f;
				ConditionData._Flood = 0.0f;
				ConditionData._Summer = 0.0f;
				ConditionData._Snow = 0.0f;
				//ConditionData._Autumn = 0.0f;
				//ConditionData._DryAutumn = 0.0f;
			//	ConditionData._WetAutumn = 0.0f;
				//ConditionData._SnowNew = 0.0f
				return;
			#endif
			
			float2 Pixel = MapCoords * IndirectionMapSize + 0.5f;
			Pixel = floor( Pixel ) / IndirectionMapSize - InvIndirectionMapSize / 2.0f;
			float4 Sample = SampleProvinceEffects( Pixel );

			float ImpactTemp = Sample.g;

			float Impact = RemapClamped( ImpactTemp, 0.0f, OpacityLowImpactValue, 0.0f, 0.5f );
			Impact += RemapClamped( ImpactTemp, OpacityLowImpactValue, OpacityHighImpactValue, 0.0f, 0.5f );

			ConditionData._Drought = ( Sample.r == DROUGHT_INDEX ) * Impact;
			ConditionData._Flood = ( Sample.r == FLOOD_INDEX ) * Impact;
			ConditionData._Summer = ( Sample.r == SUMMER_INDEX ) * Impact;
			ConditionData._Snow = ( Sample.r == SNOW_INDEX ) * Impact;
			ConditionData._Autumn = ( Sample.r == AUTUMN_INDEX ) * Impact;
			ConditionData._DryAutumn = ( Sample.r == DRY_AUTUMN_INDEX ) * Impact;
			ConditionData._WetAutumn = ( Sample.r == WET_AUTUMN_INDEX ) * Impact;
			ConditionData._SnowNew = ( Sample.r == SNOWNEW_INDEX ) * Impact;
			//END SEASONS MODDED
		}

		void ApplyDroughtDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DroughtSlopeMin, 1.0f, 0.0f, 1.0f );
			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}
			
			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 DroughtDiffuse = Diffuse;
			float3 DroughtNormal = Normal;
			float4 DroughtProperties = Properties;

			float ColorPositionValue = lerp( DroughtColorMaskPositionFrom, DroughtColorMaskPositionTo, ConditionValue );
			float ColorContrastValue = lerp( DroughtColorMaskContrastFrom, DroughtColorMaskContrastTo, ConditionValue );
			float DryPositionValue = lerp( DroughtDryMaskPositionFrom, DroughtDryMaskPositionTo, ConditionValue );
			float DryContrastValue = lerp( DroughtDryMaskContrastFrom, DroughtDryMaskContrastTo, ConditionValue );
			float CracksPositionValue = lerp( DroughtCracksAreaMaskPositionFrom, DroughtCracksAreaMaskPositionTo, ConditionValue );
			float CracksContrastValue = lerp( DroughtCracksAreaMaskContrastFrom, DroughtCracksAreaMaskContrastTo, ConditionValue );

			// Dry patches
			float4 DryTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, DroughtDryTexureIndex ) );
			DryTexDiffuse.a = 1.0f - DryTexDiffuse;
			float4 DryTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, DroughtDryTexureIndex ) );
			float3 DryTexNormal = UnpackRRxGNormal( DryTexNormalRRxG ).xyz;
			float4 DryTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, DroughtDryTexureIndex ) );

			float2 DryMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * DroughtDryMaskUVTiling;
			float DryNoiseMask = PdxTex2D( ProvinceEffectsNoise, DryMaskUV ).r;

			float DryMask = LevelsScan( DryNoiseMask, DryPositionValue, DryContrastValue ) * DroughtDryTextureBlendWeight * DroughtBlendWeight;
			float2 DryBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, DryTexDiffuse.a ), float2( 1.0f - DryMask, DryMask ), DetailBlendRange * DroughtDryTextureBlendContrast);

			// Base terrain color change
			float ColorNoise = LevelsScan( DryNoiseMask, ColorPositionValue, ColorContrastValue );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, AdjustHsv( DroughtDiffuse.rgb, 0.0f, DroughtPreSaturation, DroughtPreValue ), ColorNoise );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, Overlay( DroughtDiffuse.rgb, DroughtOverlayColor ), ColorNoise );

			DryTexDiffuse.rgb = Overlay( DryTexDiffuse.rgb, DroughtDryOverlayColor );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, DryTexDiffuse.rgb, DryBlendFactors.y );
			DroughtNormal = lerp( DroughtNormal, DryTexNormal, DryBlendFactors.y );
			DroughtProperties = lerp( DroughtProperties, DryTexProperties, DryBlendFactors.y );

			float DroughtWaterMask = smoothstep( 0.0f, 0.104f, ( 1.0f - DroughtProperties.a ) * DryMask );
			if ( DroughtWaterMask > 0.0001f )
			{
				DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, DryTexDiffuse.rgb, DroughtWaterMask * 0.1f );
				DroughtProperties.a = lerp( DroughtProperties.a , DryTexProperties.a , DroughtWaterMask );
				DroughtNormal = lerp( DroughtNormal , DryTexNormal , DroughtWaterMask * 0.5f );
			}

			// Cracks Area Mask
			float2 CrackedMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * DroughtCracksAreaMaskTiling;
			float CrackedMask = PdxTex2D( ProvinceEffectsNoise, CrackedMaskUV ).r;
			CrackedMask = LevelsScan( CrackedMask, CracksPositionValue, CracksContrastValue );

			// Cracked areas
			float2 CrackedTextureUV = CalcDetailUV( WorldSpacePosXz ) * DroughtCrackedTextureUVTiling;
			float4 CrackedTexDiffuse = PdxTex2D( DetailTextures, float3( CrackedTextureUV, DroughtCracksTexureIndex ) );
			CrackedTexDiffuse.rgb = Overlay( CrackedTexDiffuse.rgb, DroughtCracksOverlayColor );
			CrackedTexDiffuse.a = 1.0f - CrackedTexDiffuse.a;
			float4 CrackedTexNormalRRxG = PdxTex2D( NormalTextures, float3( CrackedTextureUV, DroughtCracksTexureIndex ) );
			float3 CrackedTexNormal = UnpackRRxGNormal( CrackedTexNormalRRxG ).xyz;
			float4 CrackedTexProperties = PdxTex2D( MaterialTextures, float3( CrackedTextureUV, DroughtCracksTexureIndex ) );
			float2 BlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, CrackedTexDiffuse.a), float2( 1.0f - DroughtCracksTextureBlendWeight * DroughtBlendWeight, DroughtCracksTextureBlendWeight * DroughtBlendWeight ), DetailBlendRange * DroughtCracksTextureBlendContrast );
			DroughtDiffuse.rgb = lerp( DroughtDiffuse.rgb, CrackedTexDiffuse.rgb, BlendFactors.y * CrackedMask );
			DroughtNormal = lerp( DroughtNormal, CrackedTexNormal, BlendFactors.y * CrackedMask );
			DroughtProperties = lerp( DroughtProperties, CrackedTexProperties, BlendFactors.y * CrackedMask );

			// Color adjustment
			DroughtDiffuse.rgb = AdjustHsv( DroughtDiffuse.rgb, 0.0f, DroughtFinalSaturation, 1.0f );
			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse.rgb, ConditionValue );
			Normal = lerp( Normal, DroughtNormal, ConditionValue );
			Properties = lerp( Properties, DroughtProperties, ConditionValue );
		}
		//Seasons Added
		
		void ApplyAutumnDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}
			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 AutumnDiffuse = Diffuse;
			float3 AutumnNormal = Normal;
			float4 AutumnProperties = Properties;

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, AutumnSlopeMin, 1.0f, 0.0f, 1.0f );
			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float ColorPositionValue = lerp( AutumnColorMaskPositionFrom, AutumnColorMaskPositionTo, ConditionValue );
			float ColorContrastValue = lerp( AutumnColorMaskContrastFrom, AutumnColorMaskContrastTo, ConditionValue );
			float DryPositionValue = lerp( AutumnDryMaskPositionFrom, AutumnDryMaskPositionTo, ConditionValue );
			float DryContrastValue = lerp( AutumnDryMaskContrastFrom, AutumnDryMaskContrastTo, ConditionValue );
			float CracksPositionValue = lerp( AutumnCracksAreaMaskPositionFrom, AutumnCracksAreaMaskPositionTo, ConditionValue );
			float CracksContrastValue = lerp( AutumnCracksAreaMaskContrastFrom, AutumnCracksAreaMaskContrastTo, ConditionValue );

			// Dry patches
			float4 DryTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, AutumnDryTexureIndex ) );
			DryTexDiffuse.a = 1.0f - DryTexDiffuse;
			float4 DryTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, AutumnDryTexureIndex ) );
			float3 DryTexNormal = UnpackRRxGNormal( DryTexNormalRRxG ).xyz;
			float4 DryTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, AutumnDryTexureIndex ) );

			float2 DryMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * AutumnDryMaskUVTiling;
			float DryNoiseMask = PdxTex2D( ProvinceEffectsNoise, DryMaskUV ).r;

			float DryMask = LevelsScan( DryNoiseMask, DryPositionValue, DryContrastValue ) * AutumnDryTextureBlendWeight * AutumnBlendWeight;
			float2 DryBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, DryTexDiffuse.a ), float2( 1.0f - DryMask, DryMask ), DetailBlendRange );

			// Base terrain color change
			float ColorNoise = LevelsScan( DryNoiseMask, ColorPositionValue, ColorContrastValue );
			AutumnDiffuse.rgb = lerp( AutumnDiffuse.rgb, AdjustHsv( AutumnDiffuse.rgb, 0.0f, AutumnPreSaturation, AutumnPreValue ), ColorNoise );
			AutumnDiffuse.rgb = lerp( AutumnDiffuse.rgb, Overlay( AutumnDiffuse.rgb, AutumnOverlayColor ), ColorNoise );

			DryTexDiffuse.rgb = Overlay( DryTexDiffuse.rgb, AutumnDryOverlayColor );
			AutumnDiffuse.rgb = lerp( AutumnDiffuse.rgb, DryTexDiffuse.rgb, DryBlendFactors.y );
			AutumnNormal = lerp( AutumnNormal, DryTexNormal, DryBlendFactors.y );
			AutumnProperties = lerp( AutumnProperties, DryTexProperties, DryBlendFactors.y );

			// Cracks Area Mask
			float2 CrackedMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * AutumnCracksAreaMaskTiling;
			float CrackedMask = PdxTex2D( ProvinceEffectsNoise, CrackedMaskUV ).r;
			CrackedMask = LevelsScan( CrackedMask, CracksPositionValue, CracksContrastValue );

			// Cracked areas
			float2 CrackedTextureUV = CalcDetailUV( WorldSpacePosXz ) * AutumnCrackedTextureUVTiling;
			float4 CrackedTexDiffuse = PdxTex2D( DetailTextures, float3( CrackedTextureUV, AutumnCracksTexureIndex ) );
			CrackedTexDiffuse.rgb = Overlay( CrackedTexDiffuse.rgb, AutumnCracksOverlayColor );
			CrackedTexDiffuse.a = 1.0f - CrackedTexDiffuse.a;
			float4 CrackedTexNormalRRxG = PdxTex2D( NormalTextures, float3( CrackedTextureUV, AutumnCracksTexureIndex ) );
			float3 CrackedTexNormal = UnpackRRxGNormal( CrackedTexNormalRRxG ).xyz;
			float4 CrackedTexProperties = PdxTex2D( MaterialTextures, float3( CrackedTextureUV, AutumnCracksTexureIndex ) );
			float2 BlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, CrackedTexDiffuse.a), float2( 1.0f - AutumnCracksTextureBlendWeight * AutumnBlendWeight, AutumnCracksTextureBlendWeight * AutumnBlendWeight ), DetailBlendRange * AutumnCracksTextureBlendContrast );
			AutumnDiffuse.rgb = lerp( AutumnDiffuse.rgb, CrackedTexDiffuse.rgb, BlendFactors.y * CrackedMask );
			AutumnNormal = lerp( AutumnNormal, CrackedTexNormal, BlendFactors.y * CrackedMask );
			AutumnProperties = lerp( AutumnProperties, CrackedTexProperties, BlendFactors.y * CrackedMask );

			// Color adjustment
			AutumnDiffuse.rgb = AdjustHsv( AutumnDiffuse.rgb, 0.0f, AutumnFinalSaturation, 1.0f );

			Diffuse.rgb = lerp( Diffuse.rgb, AutumnDiffuse.rgb, ConditionValue );
			Normal = lerp( Normal, AutumnNormal, ConditionValue );
			Properties = lerp( Properties, AutumnProperties, ConditionValue );
		}

		//ALT DRY Autumn1
		void ApplyDryAutumnDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 DryAutumnDiffuse = Diffuse;
			float3 DryAutumnNormal = Normal;
			float4 DryAutumnProperties = Properties;

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DryAutumnSlopeMin, 1.0f, 0.0f, 1.0f );
			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float GrassPositionValue = lerp( DryAutumnGrassMaskPositionFrom, DryAutumnGrassMaskPositionTo, ConditionValue );
			float GrassContrastValue = lerp( DryAutumnGrassMaskContrastFrom, DryAutumnGrassMaskContrastTo, ConditionValue );

			// Grass patches
			float4 GrassTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, DryAutumnGrassTexureIndex ) );
			GrassTexDiffuse.a = 1.0f - GrassTexDiffuse.r;
			float4 GrassTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, DryAutumnGrassTexureIndex ) );
			float3 GrassTexNormal = UnpackRRxGNormal( GrassTexNormalRRxG ).xyz;
			float4 GrassTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, DryAutumnGrassTexureIndex ) );

			float2 GrassMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * DryAutumnGrassMaskUVTiling;
			float GrassNoiseMask = PdxTex2D( ProvinceEffectsNoise, GrassMaskUV ).r;

			float GrassMask = LevelsScan( GrassNoiseMask, GrassPositionValue, GrassContrastValue ) * DryAutumnGrassTextureBlendWeight * DryAutumnBlendWeight;
			float2 GrassBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, GrassTexDiffuse.a ), float2( 1.0f - GrassMask, GrassMask ), DetailBlendRange );

			// Apply grass color
			GrassTexDiffuse.rgb = Overlay( GrassTexDiffuse.rgb, DryAutumnGrassOverlayColor );
			DryAutumnDiffuse.rgb = lerp( DryAutumnDiffuse.rgb, GrassTexDiffuse.rgb, GrassBlendFactors.y );
			DryAutumnNormal = lerp( DryAutumnNormal, GrassTexNormal, GrassBlendFactors.y );
			DryAutumnProperties = lerp( DryAutumnProperties, GrassTexProperties, GrassBlendFactors.y );
			Diffuse.rgb = lerp( Diffuse.rgb, DryAutumnDiffuse.rgb, ConditionValue );
			Normal = lerp( Normal, DryAutumnNormal, ConditionValue );
			Properties = lerp( Properties, DryAutumnProperties, ConditionValue );
		}	
		
		
		//END ALT DRY AUTUMN

		
		//End Seasons Added
		void ApplyFloodingDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue, inout float WaterNormalLerp )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}
			ConditionValue *= 0.95f;

			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 TextureUV = MapCoords * float2( 2.0f, 1.0f );
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz ) * FloodDetailTiling;

			float AdjustedPositionValue = lerp( FloodNoisePositionFrom, FloodNoisePositionTo, ConditionValue );
			float AdjustedContrastValue = lerp( FloodNoiseContrastFrom, FloodNoiseContrastTo, ConditionValue );

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, FloodSlopeMin, 1.0f, 0.0f, 1.0f );

			float4 FloodTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, FloodTextureIndex ) );
			float4 FloodTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, FloodTextureIndex ) );
			float3 FloodTexNormal = UnpackRRxGNormal( FloodTexNormalRRxG ).xyz;
			float4 FloodTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, FloodTextureIndex ) );

			float2 FloodNoiseUV = TextureUV * FloodNoiseTiling;
			float FloodNoise = PdxTex2D( ProvinceEffectsNoise, FloodNoiseUV ).r;
			float FloodNoiseFill = LevelsScan( FloodNoise, AdjustedPositionValue, AdjustedContrastValue );
			FloodNoise = FloodNoiseFill * SlopeMultiplier;
			float2 FloodBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, FloodTexDiffuse.a ), float2( 1.0f - FloodNoise, FloodNoise ), DetailBlendRange * 2.0f );

			// Watercolor
			float4 FloodWaterColor = lerp( float4( FloodWaterInnerColor, 1.0f ), float4( FloodWaterEdgeColor, 1.0f ), FloodBlendFactors.y * FloodNoiseFill );

			// Apply Water Color
			float4 FloodDiffuse = lerp( Diffuse, FloodWaterColor, FloodBlendFactors.y * FloodWaterOpacity );
			float3 FloodNormal = lerp( Normal, FloodNormalDirection, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			float4 FloodProperties = lerp( Properties, FloodPropertiesSettings, FloodBlendFactors.y * FloodWaterPropertiesBlend );
			WaterNormalLerp = FloodBlendFactors.y;
			WaterNormalLerp = smoothstep( 0.8f, 1.0f, WaterNormalLerp );

			// Apply Flood
			FloodDiffuse.rgb = lerp( FloodDiffuse.rgb, FloodDiffuse.rgb * FloodDiffuseWetMultiplier, ConditionValue );
			FloodProperties.a = lerp( FloodProperties.a, FloodProperties.a * FloodPropertiesWetMultiplier, ConditionValue );

			Diffuse = lerp( Diffuse, FloodDiffuse, ConditionValue );
			Normal = lerp( Normal, FloodNormal, ConditionValue );
			Properties = lerp( Properties, FloodProperties, ConditionValue );
		}

		void ApplySummerDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 SummerDiffuse = Diffuse;
			float3 SummerNormal = Normal;
			float4 SummerProperties = Properties;

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, SummerSlopeMin, 1.0f, 0.0f, 1.0f );
			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float GrassPositionValue = lerp( SummerGrassMaskPositionFrom, SummerGrassMaskPositionTo, ConditionValue );
			float GrassContrastValue = lerp( SummerGrassMaskContrastFrom, SummerGrassMaskContrastTo, ConditionValue );

			// Grass patches
			float4 GrassTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, SummerGrassTexureIndex ) );
			GrassTexDiffuse.a = 1.0f - GrassTexDiffuse.r;
			float4 GrassTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, SummerGrassTexureIndex ) );
			float3 GrassTexNormal = UnpackRRxGNormal( GrassTexNormalRRxG ).xyz;
			float4 GrassTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, SummerGrassTexureIndex ) );

			float2 GrassMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * SummerGrassMaskUVTiling;
			float GrassNoiseMask = PdxTex2D( ProvinceEffectsNoise, GrassMaskUV ).r;

			float GrassMask = LevelsScan( GrassNoiseMask, GrassPositionValue, GrassContrastValue ) * SummerGrassTextureBlendWeight * SummerBlendWeight;
			float2 GrassBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, GrassTexDiffuse.a ), float2( 1.0f - GrassMask, GrassMask ), DetailBlendRange );

			// Apply grass color
			GrassTexDiffuse.rgb = Overlay( GrassTexDiffuse.rgb, SummerGrassOverlayColor );
			SummerDiffuse.rgb = lerp( SummerDiffuse.rgb, GrassTexDiffuse.rgb, GrassBlendFactors.y );
			SummerNormal = lerp( SummerNormal, GrassTexNormal, GrassBlendFactors.y );
			SummerProperties = lerp( SummerProperties, GrassTexProperties, GrassBlendFactors.y );
			Diffuse.rgb = lerp( Diffuse.rgb, SummerDiffuse.rgb, ConditionValue );
			Normal = lerp( Normal, SummerNormal, ConditionValue );
			Properties = lerp( Properties, SummerProperties, ConditionValue );
		}
//SEASONS ADDED NEW SNOW TESTING

		void ApplySnowNewDiffuseTerrain( inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float2 MapCoords = WorldSpacePosXz * WorldSpaceToTerrain0To1;
			float2 DetailUV = CalcDetailUV( WorldSpacePosXz );

			float4 SnowDiffuse = Diffuse;
			float3 SnowNormal = Normal;
			float4 SnowProperties = Properties;

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, SnowSlopeMin, 1.0f, 0.0f, 1.0f );
			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float GrassPositionValue = lerp( SnowGrassMaskPositionFrom, SnowGrassMaskPositionTo, ConditionValue );
			float GrassContrastValue = lerp( SnowGrassMaskContrastFrom, SnowGrassMaskContrastTo, ConditionValue );

			// Grass patches
			float4 GrassTexDiffuse = PdxTex2D( DetailTextures, float3( DetailUV, SnowGrassTexureIndex ) );
			GrassTexDiffuse.a = 1.0f - GrassTexDiffuse.r;
			float4 GrassTexNormalRRxG = PdxTex2D( NormalTextures, float3( DetailUV, SnowGrassTexureIndex ) );
			float3 GrassTexNormal = UnpackRRxGNormal( GrassTexNormalRRxG ).xyz;
			float4 GrassTexProperties = PdxTex2D( MaterialTextures, float3( DetailUV, SnowGrassTexureIndex ) );

			float2 GrassMaskUV = float2( MapCoords.x * 2.0f, MapCoords.y ) * SnowGrassMaskUVTiling;
			float GrassNoiseMask = PdxTex2D( ProvinceEffectsNoise, GrassMaskUV ).r;

			float GrassMask = LevelsScan( GrassNoiseMask, GrassPositionValue, GrassContrastValue ) * SnowGrassTextureBlendWeight * SnowBlendWeight;
			float2 GrassBlendFactors = CalcHeightBlendFactors( float2( Diffuse.a, GrassTexDiffuse.a ), float2( 1.0f - GrassMask, GrassMask ), DetailBlendRange );

			// Apply grass color
			GrassTexDiffuse.rgb = SnowGrassOverlayColor;//Overlay( GrassTexDiffuse.rgb, SnowGrassOverlayColor );
			SnowDiffuse.rgb = lerp( SnowDiffuse.rgb, GrassTexDiffuse.rgb, GrassBlendFactors.y );
			SnowNormal = lerp( SnowNormal, GrassTexNormal, GrassBlendFactors.y );
			SnowProperties = lerp( SnowProperties, GrassTexProperties, GrassBlendFactors.y );
			Diffuse.rgb = lerp( Diffuse.rgb, SnowDiffuse.rgb, ConditionValue );
			Normal = lerp( Normal, SnowNormal, ConditionValue );
			Properties = lerp( Properties, SnowProperties, ConditionValue );
		}




//END SEASONS ADDED NEW SNOW


		void ApplyProvinceEffectsTerrain( in EffectIntensities ConditionData, inout float4 Diffuse, inout float3 Normal, inout float4 Properties, float3 WorldSpacePos, inout float WaterNormalLerp )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			
			//MOD SEASONS
			// Do not apply any effects to the snow.
			//float3 SnowColor = float3( 0.1f, 0.1f, 0.1f );
		//	if ( !any( abs( Diffuse.rgb - SnowColor ) >= 0.45f ) )
		//	{
		//		return;
		//	}
			//END MOD SEASONS
			ApplyDroughtDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._Drought );

			ApplyFloodingDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._Flood, WaterNormalLerp );
			ApplySummerDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._Summer );
			//Seasons Added
			ApplyDryAutumnDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._DryAutumn );
			ApplyDryAutumnDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._Autumn );
			ApplyDryAutumnDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._WetAutumn );
			ApplySnowNewDiffuseTerrain( Diffuse, Normal, Properties, WorldSpacePos.xz, ConditionData._SnowNew );
			//End Seasons
			DebugCondition( Diffuse.rgb, ConditionData );
		}

		void ApplyDroughtDiffuseTree( inout float4 Diffuse, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DroughtSlopeMin, 1.0f, 0.0f, 1.0f );

			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 DroughtDiffuse = AdjustHsv( Diffuse.rgb, 0.0f, DroughtPreSaturation, DroughtPreValue );
			DroughtDiffuse = Overlay( DroughtDiffuse, DroughtOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse, ConditionValue );
			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.8f, 0.85f, Diffuse.a ), ConditionValue );
		}

		void ApplySummerDiffuseTree( inout float4 Diffuse, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, SummerSlopeMin, 1.0f, 0.0f, 1.0f );

			ConditionValue = ConditionValue * SlopeMultiplier * SummerBlendWeight;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 SummerDiffuse = Overlay( Diffuse.rgb, SummerOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, SummerDiffuse, ConditionValue );
		}
		//#SEASONS ADDED 
		
		void ApplyAutumnDiffuseTree( inout float4 Diffuse, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, SummerSlopeMin, 1.0f, 0.0f, 1.0f );

			ConditionValue = ConditionValue * SlopeMultiplier * AutumnBlendWeight;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 AutumnDiffuse = Overlay( Diffuse.rgb, AutumnOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, AutumnDiffuse, ConditionValue );
		}
		void ApplyDryAutumnDiffuseTree( inout float4 Diffuse, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, DryAutumnSlopeMin, 1.0f, 0.0f, 1.0f );

			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 DryAutumnDiffuse = AdjustHsv( Diffuse.rgb, 0.0f, DryAutumnPreSaturation, DryAutumnPreValue );
			DryAutumnDiffuse = Overlay( DryAutumnDiffuse, DryAutumnOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, DryAutumnDiffuse, ConditionValue );
			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.0f, 2.0f, Diffuse.a ), ConditionValue );
		}
		void ApplyWetAutumnDiffuseTree( inout float4 Diffuse, float2 WorldSpacePosXz, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float SlopeMultiplier = dot( CalculateNormal( WorldSpacePosXz ), UP_VECTOR );
			SlopeMultiplier = RemapClamped( SlopeMultiplier, 0.1f, 1.0f, 0.0f, 1.0f );

			ConditionValue *= SlopeMultiplier;

			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 WetAutumnDiffuse = AdjustHsv( Diffuse.rgb, 0.0f, 1.2f, WetAutumnPreValue );
			WetAutumnDiffuse = Overlay( WetAutumnDiffuse, WetAutumnOverlayTree );
			Diffuse.rgb = lerp( Diffuse.rgb, WetAutumnDiffuse, ConditionValue );
			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.0f, 2.0f, Diffuse.a ), ConditionValue );
		}
		//#END ADDED SEASONS

		void ApplySnowDiffuseTree( inout float4 Diffuse, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			Diffuse.a = lerp( Diffuse.a, smoothstep( 0.8f, 0.85f, Diffuse.a ), ConditionValue );
		}

		void ApplyProvinceEffectsTree( in EffectIntensities ConditionData, inout float4 Diffuse, float2 MapCoords, float2 WorldSpacePosXz )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			//SEASONS MODDED
			ApplyDroughtDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Drought );
			ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Summer );
			ApplySnowDiffuseTree( Diffuse, ConditionData._Snow );
			ApplyAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			ApplyDryAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._DryAutumn );
			ApplyWetAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._WetAutumn );
			//ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			
			DebugCondition( Diffuse.rgb, ConditionData );
		}
		void ApplyProvinceEffectsTree_yellow( in EffectIntensities ConditionData, inout float4 Diffuse, float2 MapCoords, float2 WorldSpacePosXz )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			//SEASONS MODDED
			ApplyDroughtDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Drought );
			ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Summer );
			ApplySnowDiffuseTree( Diffuse, ConditionData._Snow );
			ApplyWetAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			ApplyWetAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._DryAutumn );
			ApplyWetAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._WetAutumn );
			//ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			
			DebugCondition( Diffuse.rgb, ConditionData );
		}
		void ApplyProvinceEffectsTree_red( in EffectIntensities ConditionData, inout float4 Diffuse, float2 MapCoords, float2 WorldSpacePosXz )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			//SEASONS MODDED
			ApplyDroughtDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Drought );
			ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Summer );
			ApplySnowDiffuseTree( Diffuse, ConditionData._Snow );
			ApplyAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			ApplyAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._DryAutumn );
			ApplyAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._WetAutumn );
			//ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			
			DebugCondition( Diffuse.rgb, ConditionData );
		}
		void ApplyProvinceEffectsTree_orange( in EffectIntensities ConditionData, inout float4 Diffuse, float2 MapCoords, float2 WorldSpacePosXz )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			//SEASONS MODDED
			ApplyDroughtDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Drought );
			ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Summer );
			ApplySnowDiffuseTree( Diffuse, ConditionData._Snow );
			ApplyDryAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			ApplyDryAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._DryAutumn );
			ApplyDryAutumnDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._WetAutumn );
			//ApplySummerDiffuseTree( Diffuse, WorldSpacePosXz, ConditionData._Autumn );
			
			DebugCondition( Diffuse.rgb, ConditionData );
		}
		void ApplyDroughtDiffuseDecal( inout float3 Diffuse, float ConditionValue )
		{
			if ( ConditionValue <= SKIP_VALUE )
			{
				return;
			}

			float3 DroughtDiffuse = Diffuse;
			DroughtDiffuse = AdjustHsv( DroughtDiffuse, 0.0f, DroughtDecalPreSaturation, DroughtDecalPreValue );
			DroughtDiffuse = Overlay( DroughtDiffuse, DroughtOverlayDecal );
			DroughtDiffuse = AdjustHsv( DroughtDiffuse, 0.0f, DroughtDecalFinalSaturation, 1.0f );
			Diffuse.rgb = lerp( Diffuse.rgb, DroughtDiffuse, ConditionValue );
		}

		void ApplyProvinceEffectsDecal( in EffectIntensities ConditionData, inout float3 Diffuse, float2 MapCoords )
		{
			#ifdef LOW_SPEC_SHADERS
				return;
			#endif
			ApplyDroughtDiffuseDecal( Diffuse, ConditionData._Drought );

			DebugCondition( Diffuse.rgb, ConditionData );
		}
	]]
}
