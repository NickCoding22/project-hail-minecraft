#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int biome_category;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

float hash(float n) { return fract(sin(n) * 43758.5453123); }
#define CAT_THE_END 8

void main() {
    vec4 sceneColor = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    // Camera ray in world space
    vec4 ndcPos = vec4(texcoord * 2.0 - 1.0, 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= max(viewPos.w, 1e-6);
    vec4 playerSpaceDir = gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);
    vec3 rayDir = normalize(playerSpaceDir.xyz);

    vec3 ro = cameraPosition;

    // Reconstruct geometry hit distance for depth testing effects.
    float sceneDist = 1e20;
    if (depth < 0.999999) {
        vec4 blockNDC = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        vec4 blockView = gbufferProjectionInverse * blockNDC;
        blockView /= max(blockView.w, 1e-6);
        vec4 blockWorld = gbufferModelViewInverse * blockView;
        sceneDist = length(blockWorld.xyz - ro);
    }

    // Petrova line: curved cylindrical tube passing by the planet (torus path).
    vec3 beaconPos = vec3(0.0, 30.0, 0.0);
    float redIntensity = 1.0;
    float petrovaHeight = beaconPos.y + 128.0;
    float petrovaPathRadius = 202.0;
    float petrovaTubeRadius = 5.2;
    vec3 ringCenter = vec3(beaconPos.x, petrovaHeight, beaconPos.z);

    // Camera state for "inside the Petrova line" effects.
    vec3 camRel = ro - ringCenter;
    float camRadial = length(camRel.xz);
    float camTubeDist = length(vec2(camRadial - petrovaPathRadius, camRel.y));
    bool insidePetrova = camTubeDist < petrovaTubeRadius * 1.05;

    if (biome_category == CAT_THE_END) {
        float maxTraceDist = min(sceneDist, 380.0);
        float t = 0.0;
        float lineGlow = 0.0;
        float sparkleAmount = 0.0;
        for (int i = 0; i < 28; i++) {
            if (t > maxTraceDist) break;
            vec3 p = ro + rayDir * t;
            vec3 q = p - ringCenter;
            float radial = length(q.xz);
            float tubeDist = length(vec2(radial - petrovaPathRadius, q.y));

            float shellMask = 1.0 - smoothstep(petrovaTubeRadius, petrovaTubeRadius + 1.8, tubeDist);
            if (shellMask > 1e-4) {
                float ang = atan(q.z, q.x);
                float sweep = sin(ang * 22.0 - frameTimeCounter * 4.9) * 0.5 + 0.5;
                float pulse = sin(frameTimeCounter * 8.5 + ang * 3.5) * 0.5 + 0.5;
                float modMask = (0.52 + 0.48 * sweep) * (0.7 + 0.3 * pulse);
                float localGlow = shellMask * modMask;
                lineGlow = max(lineGlow, localGlow);

                // Sparkles/dots are directly bound to Petrova geometry and animation.
                vec3 cell = floor(p * 0.22);
                float hr = hash(cell.x * 117.0 + cell.y * 313.0 + cell.z * 71.0);
                if (hr > 0.84) {
                    float twinkle = sin(frameTimeCounter * 10.0 + hr * 23.0 + ang * 5.0) * 0.5 + 0.5;
                    sparkleAmount += localGlow * twinkle * smoothstep(0.84, 1.0, hr);
                }
            }
            t += 8.0;
        }

        if (lineGlow > 0.0) {
            vec3 lineCol = vec3(1.0, 0.02, 0.02);
            sceneColor.rgb += lineCol * lineGlow * (1.55 + redIntensity * 0.5);
        }
        if (sparkleAmount > 0.0) {
            vec3 sparkleColor = vec3(1.0, 1.0, 1.0);
            sceneColor.rgb += sparkleColor * min(sparkleAmount * 0.42, 1.5);
        }

        // Entering the Petrova line: red screen tint + fast white particle fly-by.
        if (insidePetrova) {
            float insideStrength = 1.0 - smoothstep(petrovaTubeRadius * 0.45, petrovaTubeRadius * 1.05, camTubeDist);
            vec3 redFog = vec3(0.95, 0.02, 0.04);
            sceneColor.rgb = mix(sceneColor.rgb, vec3(sceneColor.r, sceneColor.g * 0.18, sceneColor.b * 0.22), 0.75 * insideStrength);
            sceneColor.rgb = mix(sceneColor.rgb, redFog, 0.5 * insideStrength);

            float particleAmount = 0.0;
            for (int i = 1; i <= 8; i++) {
                vec3 samplePos = ro + rayDir * (float(i) * 6.0);
                samplePos.y -= frameTimeCounter * 2.0;
                samplePos += vec3(0.0, 0.0, frameTimeCounter * 0.9);

                vec3 cellId = floor(samplePos * 0.75);
                vec3 localPos = fract(samplePos * 0.75) - 0.5;
                float r = hash(cellId.x * 127.0 + cellId.y * 311.0 + cellId.z * 73.0);

                if (r > 0.82) {
                    float dist = length(localPos);
                    float twinkle = sin(frameTimeCounter * 9.0 + r * 25.0) * 0.5 + 0.5;
                    particleAmount += smoothstep(0.22, 0.0, dist) * twinkle;
                }
            }
            sceneColor.rgb += vec3(1.0) * min(particleAmount * 0.55, 1.6) * insideStrength;
        }
    }

    color = sceneColor;
}