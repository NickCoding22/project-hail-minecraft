#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float far;
uniform float frameTimeCounter;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float hash(float n) { return fract(sin(n) * 43758.5453123); }

void main() {
    vec4 sceneColor = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    // cam ray
    vec4 ndcPos = vec4(texcoord * 2.0 - 1.0, 1.0, 1.0); 
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= viewPos.w;
    vec4 playerSpaceDir = gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);
    vec3 rayDir = normalize(playerSpaceDir.xyz);

    // static beacon
    vec3 beaconPos = vec3(0.0, 100.0, 0.0);
    float beaconRadius = 6.0;
    float effectRadius = 50.0;

    // dist for light change
    float distToBeacon = distance(cameraPosition, beaconPos);
    float redIntensity = smoothstep(effectRadius, 10.0, distToBeacon);

    // red color shift
    mat3 redShift = mat3(
        1.2, 0.0, 0.0,  
        0.0, 0.3, 0.0,  
        0.0, 0.0, 0.4   
    );
    vec3 normalColor = sceneColor.rgb;
    vec3 shiftedColor = normalColor * redShift;
    sceneColor.rgb = mix(normalColor, shiftedColor, redIntensity);

    vec2 p = beaconPos.xz - cameraPosition.xz;
    vec2 d = normalize(rayDir.xz);
    float isForward = dot(d, normalize(p));

    if (isForward > 0.0) {
        float distToBeam = abs(p.x * d.y - p.y * d.x);
        
        if (distToBeam < beaconRadius) {
            float beamDist = dot(p, d);
            
            vec4 blockNDC = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
            vec4 blockView = gbufferProjectionInverse * blockNDC;
            blockView /= blockView.w;
            vec4 blockPlayerSpace = gbufferModelViewInverse * blockView;
            float blockDist = length(blockPlayerSpace.xz);

            if (depth == 1.0 || beamDist < blockDist) {
                vec3 beamColor = vec3(1.0, 0.2, 0.0);
                float beamFade = pow(smoothstep(beaconRadius, 0.0, distToBeam), 1.5); 
                sceneColor.rgb += beamColor * beamFade * 1.5; 
            }
        }
    }

    // dust particles
    if (redIntensity > 0.0) {
        float sparkleAmount = 0.0;
        
        for(int i = 1; i <= 5; i++) {
            vec3 samplePos = rayDir * (float(i) * 3.0) + cameraPosition * 0.5;
            samplePos.y -= frameTimeCounter * 0.4; 
            
            vec3 cellId = floor(samplePos);
            vec3 localPos = fract(samplePos) - 0.5; 
            
            float r = hash(cellId.x * 123.0 + cellId.y * 311.0 + cellId.z * 73.0);
            
            if(r > 0.85) { 
                float dist = length(localPos);
                float twinkle = sin(frameTimeCounter * 4.0 + r * 10.0) * 0.5 + 0.5;
                sparkleAmount += smoothstep(0.15, 0.0, dist) * twinkle;
            }
        }
        
        vec3 sparkleColor = vec3(1.0, 0.5, 0.1); 
        sceneColor.rgb += sparkleColor * sparkleAmount * redIntensity * 4.0;
    }

    color = sceneColor;
}