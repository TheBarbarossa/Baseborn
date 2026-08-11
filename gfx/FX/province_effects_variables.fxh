PixelShader = {
	Code
	[[
		static const int DROUGHT_INDEX = 1;
		static const int FLOOD_INDEX = 2;
		static const int SUMMER_INDEX = 3;
		static const int SNOW_INDEX = 4;
		static const int AUTUMN_INDEX = 5;
		static const int DRY_AUTUMN_INDEX = 6;
		static const int WET_AUTUMN_INDEX = 7;
		static const int SNOWNEW_INDEX = 8;
		// General
		#define OpacityLowImpactValue				0.1f
		#define OpacityHighImpactValue				1.0f

		// Drought
		#define DroughtBlendWeight					1.00f
		#define DroughtSlopeMin						0.2f
		#define DroughtPreSaturation				0.8f
		#define DroughtPreValue						0.8f
		#define DroughtFinalSaturation				0.7f
		#define DroughtOverlayColor					float3( 0.7020f, 0.3569f, 0.0f )

		#define DroughtDryOverlayColor				float3( 0.200f, 0.133f, 0.078f )

		#define DroughtCracksOverlayColor			float3( 0.357f, 0.188f, 0.047f )



		#define DroughtColorMaskPositionFrom		1.0f

		#define DroughtColorMaskPositionTo			0.1f



		#define DroughtColorMaskContrastFrom		1.0f

		#define DroughtColorMaskContrastTo			0.9f



		#define DroughtDryTexureIndex				0

		#define DroughtDryMaskUVTiling				15

		#define DroughtDryTextureBlendWeight		0.35f

		#define DroughtDryTextureBlendContrast		1.8f

		

		#define DroughtDryMaskPositionFrom			1.05f

		#define DroughtDryMaskPositionTo			0.60f



		#define DroughtDryMaskContrastFrom			0.455f

		#define DroughtDryMaskContrastTo			0.905f





		#define DroughtCracksTexureIndex			1

		#define DroughtCrackedTextureUVTiling		2

		#define DroughtCracksAreaMaskTiling			10.0f



		#define DroughtCracksAreaMaskPositionFrom	0.7f

		#define DroughtCracksAreaMaskPositionTo		0.6f

		

		#define DroughtCracksAreaMaskContrastFrom	0.7f

		#define DroughtCracksAreaMaskContrastTo		0.101f



		#define DroughtCracksTextureBlendWeight		0.28f

		#define DroughtCracksTextureBlendContrast	1.5f



		#define DroughtOverlayTree 					float3( 2.550f, 1.490f, 0.000f )



		#define DroughtDecalPreSaturation 			0.0f

		#define DroughtDecalPreValue 				0.8f

		#define DroughtDecalFinalSaturation 		0.4f

		#define DroughtOverlayDecal 				float3( 0.7020f, 0.3569f, 0.0f )



		// Flooding

		#define FloodSlopeMin						0.98f

		#define FloodTextureIndex					2



		#define FloodNoiseTiling					30

		#define FloodDetailTiling					0.5f

		

		#define FloodWaterOpacity 					0.92f

		#define FloodWaterPropertiesBlend			0.995f

		#define FloodNormalDirection				float3( 0.0f, 0.0f, 1.0f )

		#define FloodPropertiesSettings 			float4( 0.0f, 0.03f, 0.0f, 0.1f )

		

		#define FloodDiffuseWetMultiplier			0.5f

		#define FloodPropertiesWetMultiplier		0.60f

		#define FloodNoisePositionFrom				0.75f

		#define FloodNoisePositionTo				0.5f

		#define FloodNoiseContrastFrom				0.1f

		#define FloodNoiseContrastTo				0.45f



		#define FloodWaterInnerColor				float3( 0.0392f, 0.0353f, 0.0078f )

		#define FloodWaterEdgeColor					float3( 0.0275f, 0.0471f, 0.0902f )



		// Summer

		#define SummerBlendWeight					1.0f

		#define SummerSlopeMin						0.2f

		#define SummerGrassOverlayColor 			float3( 0.2824f, 0.4471f, 0.1216f )



		#define SummerGrassTexureIndex				3

		#define SummerGrassMaskUVTiling				15

		#define SummerGrassTextureBlendWeight		0.5f

		

		#define SummerGrassMaskPositionFrom			1.05f

		#define SummerGrassMaskPositionTo			0.50f



		#define SummerGrassMaskContrastFrom			0.455f

		#define SummerGrassMaskContrastTo			0.905f

		#define SummerOverlayTree					float3( 0.4196f, 0.6941f, 0.4078f) 
		//NEW SNOW 
		// Summer

		#define SnowBlendWeight					1.0f

		#define SnowSlopeMin						0.2f

		#define SnowGrassOverlayColor 			float3( 1.0f, 1.0f, 1.0f )



		#define SnowGrassTexureIndex				3

		#define SnowGrassMaskUVTiling				15

		#define SnowGrassTextureBlendWeight		0.7f

		

		#define SnowGrassMaskPositionFrom			1.05f

		#define SnowGrassMaskPositionTo			0.50f



		#define SnowGrassMaskContrastFrom			0.455f

		#define SnowGrassMaskContrastTo			0.905f

		#define SnowOverlayTree					float3( 0.4196f, 0.6941f, 0.4078f) 
		
		//END NEW SNOW
		//Autumn
		
		#define AutumnBlendWeight					2.00f
		#define AutumnSlopeMin						0.1f
		#define AutumnPreSaturation					0.8f
		#define AutumnPreValue						0.8f
		#define AutumnFinalSaturation				0.7f
		#define AutumnOverlayColor					float3( 0.171f, 0.790f, 0.120f )
		#define AutumnDryOverlayColor				float3( 2.190f, 2.212f, 0.090f )
		#define AutumnCracksOverlayColor			float3( 0.357f, 0.188f, 0.047f )

		#define AutumnColorMaskPositionFrom		1.0f
		#define AutumnColorMaskPositionTo			0.1f

		#define AutumnColorMaskContrastFrom		1.0f
		#define AutumnColorMaskContrastTo			0.9f

		#define AutumnDryTexureIndex				56
		#define AutumnDryMaskUVTiling				15
		#define AutumnDryTextureBlendWeight		0.35f
		
		#define AutumnDryMaskPositionFrom			1.05f
		#define AutumnDryMaskPositionTo			0.60f

		#define AutumnDryMaskContrastFrom			0.455f
		#define AutumnDryMaskContrastTo			0.905f


		#define AutumnCracksTexureIndex			57
		#define AutumnCrackedTextureUVTiling		2
		#define AutumnCracksAreaMaskTiling			10.0f

		#define AutumnCracksAreaMaskPositionFrom	0.761f
		#define AutumnCracksAreaMaskPositionTo		0.5f
		
		#define AutumnCracksAreaMaskContrastFrom	0.7f
		#define AutumnCracksAreaMaskContrastTo		0.101f

		#define AutumnCracksTextureBlendWeight		0.28f
		#define AutumnCracksTextureBlendContrast	1.5f
		#define AutumnOverlayTree 					float3( 1.680f, 0.260f, 0.130f )

		#define AutumnDecalPreSaturation 			0.0f
		#define AutumnDecalPreValue 				0.2f
		#define AutumnDecalFinalSaturation 		0.4f
		#define AutumnOverlayDecal 				float3( 1.000f, 0.402f, 0.0f )
		
		
				//Dry Autumn
				
				
		//ALT Dry Autumn
		#define DryAutumnBlendWeight					2.0f
		#define DryAutumnSlopeMin						0.1f
		#define DryAutumnGrassOverlayColor 			float3( 0.651f, 0.396f, 0.192f )
		#define DryAutumnPreSaturation					0.8f
		#define DryAutumnGrassTexureIndex				59
		#define DryAutumnGrassMaskUVTiling				15
		#define DryAutumnGrassTextureBlendWeight		0.5f
		#define DryAutumnPreValue						0.8f		
		#define DryAutumnGrassMaskPositionFrom			1.05f
		#define DryAutumnGrassMaskPositionTo			0.50f

		#define DryAutumnGrassMaskContrastFrom			0.455f
		#define DryAutumnGrassMaskContrastTo			0.905f
		#define DryAutumnOverlayTree					float3( 1.810f, 0.330f, 0.000f )
	
		//Wet Autumn Leafs (Yellow?)
		#define WetAutumnOverlayTree 					float3( 2.550f, 2.550f, 0.500f )
		
		
		//END ALT
		//WET Autumn
		#define WetAutumnSlopeMin						0.98f
		#define WetAutumnTextureIndex					58
		#define WetAutumnNoiseTiling					30
		#define WetAutumnDetailTiling					0.5f
		#define WetAutumnPreSaturation					0.8f		
		#define WetAutumnWaterOpacity 					0.92f
		#define WetAutumnWaterPropertiesBlend			0.995f
		#define WetAutumnNormalDirection				float3( 0.0f, 0.0f, 1.0f )
		#define WetAutumnPropertiesSettings 			float4( 0.0f, 0.125f, 0.0f, 0.08f )
		#define WetAutumnPreValue						0.8f
		#define WetAutumnDiffuseWetMultiplier			0.5f
		#define WetAutumnPropertiesWetMultiplier		0.60f

		#define WetAutumnNoisePositionFrom				0.75f
		#define WetAutumnNoisePositionTo				0.5f
		#define WetAutumnNoiseContrastFrom				0.1f
		#define WetAutumnNoiseContrastTo				0.45f

		#define WetAutumnWaterInnerColor				float3( 0.053f, 0.055f, 0.074f )
		#define WetAutumnWaterEdgeColor					float3( 0.088f, 0.073f, 0.052f )
	]]
}