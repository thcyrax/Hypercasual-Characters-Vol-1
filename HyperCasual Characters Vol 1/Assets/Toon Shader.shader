Shader "Custom/Toon Shader"
{
    Properties {
        _MainTex ("Base Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        _ShadeColor ("Shade Color", Color) = (0.2, 0.2, 0.2, 1) // Color de la sombra
        _Cutoff ("Light Cutoff", Range(0,1)) = 0.5
        _Smoothness ("Shade Smoothness", Range(0.01, 1)) = 0.1 // Suavizado del borde del sombreado
        _ShadeIntensity ("Shade Intensity", Range(0,1)) = 1.0 // Intensidad del sombreado
        _UseRim ("Use Rim Light", Float) = 1 // Controla si el Rim Light está activo o no
        _RimColor ("Rim Light Color", Color) = (1,1,1,1)
        _RimPower ("Rim Light Power", Range(0.1, 4)) = 1
        _RimIntensity ("Rim Light Intensity", Range(0, 1)) = 0.5 // Intensidad del Rim Light
    }

    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _Color;
            float4 _ShadeColor;
            float _Cutoff;
            float _Smoothness;
            float _ShadeIntensity;
            float _UseRim;
            float4 _RimColor;
            float _RimPower;
            float _RimIntensity;

            v2f vert (appdata_t v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.uv = v.uv;

                // Calculate view direction for rim light
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // Sample texture
                fixed4 tex = tex2D(_MainTex, i.uv) * _Color;

                // Calculate light direction and intensity for toon shading
                float NdotL = dot(i.normal, i.lightDir);

                // Toon shading: smooth shading based on _Cutoff and _Smoothness
                float shading = smoothstep(_Cutoff - _Smoothness, _Cutoff + _Smoothness, NdotL);

                // Apply shade intensity
                shading = lerp(1.0, shading, _ShadeIntensity);

                // Blend shading with base color using multiply (darken-like effect)
                float3 blendedColor = tex.rgb * lerp(float3(1.0, 1.0, 1.0), _ShadeColor.rgb, 1.0 - shading);

                // Rim light (only if _UseRim is enabled)
                float3 finalColor = blendedColor;
                if (_UseRim > 0.5) {
                    // Rim light: highlight edges based on view direction
                    float rim = 1.0 - saturate(dot(i.normal, i.viewDir));
                    float3 rimColor = pow(rim, _RimPower) * _RimColor.rgb * _RimIntensity;
                    finalColor += rimColor;
                }

                return fixed4(finalColor, tex.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
