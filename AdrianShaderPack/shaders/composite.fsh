#version 330 compatibility

// menu
#define ENABLE_ADRIAN_ATMOSPHERE // [toggle]
#define ENABLE_PETROVA_LINE // [toggle]
#define ENABLE_ASTROPHAGE_SWARM // [toggle]
#define REDSHIFT_POWER 0.75 // [0.25 0.50 0.75 1.00 1.25]
#define SWARM_DENSITY 0.82 // [0.70 0.75 0.80 0.82 0.85 0.90]

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
float swirlField(vec3 p, float t) {
    float a = sin(p.x * 0.11 + t * 0.9) * cos(p.z * 0.10 - t * 0.7);
    float b = sin((p.x + p.y) * 0.08 - t * 0.6) * cos((p.z - p.y) * 0.09 + t * 0.8);
    float c = sin(length(p.xz) * 0.14 + t * 1.1 + p.y * 0.05);
    return clamp((a * 0.45 + b * 0.35 + c * 0.2) * 0.5 + 0.5, 0.0, 1.0);
}
#define CAT_THE_END 8

void main() {
    vec4 sceneColor = texture(colortex0, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    vec4 ndcPos = vec4(texcoord * 2.0 - 1.0, 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * ndcPos;
    viewPos /= max(viewPos.w, 1e-6);
    vec4 playerSpaceDir = gbufferModelViewInverse * vec4(viewPos.xyz, 0.0);
    vec3 rayDir = normalize(playerSpaceDir.xyz);
    vec3 ro = cameraPosition;

    float sceneDist = 1e20;
    vec3 sceneWorldPos = ro + rayDir * sceneDist;
    bool hasSceneGeometry = depth < 0.999999;
    if (depth < 0.999999) {
        vec4 blockNDC = vec4(texcoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        vec4 blockView = gbufferProjectionInverse * blockNDC;
        blockView /= max(blockView.w, 1e-6);
        vec4 blockWorld = gbufferModelViewInverse * blockView;
        sceneWorldPos = blockWorld.xyz;
        sceneDist = length(sceneWorldPos - ro);
    }

    vec3 beaconPos = vec3(0.0, 30.0, 0.0);
    float petrovaHeight = beaconPos.y + 128.0;
    float petrovaPathRadius = 202.0;
    float petrovaTubeRadius = 5.2;
    vec3 ringCenter = vec3(beaconPos.x, petrovaHeight, beaconPos.z);

    vec3 camRel = ro - ringCenter;
    float camRadial = length(camRel.xz);
    float camTubeDist = length(vec2(camRadial - petrovaPathRadius, camRel.y));
    bool insidePetrova = camTubeDist < petrovaTubeRadius * 1.05;
    bool handLikeForeground = depth <= 0.00002;

    if (biome_category == CAT_THE_END) {
        float cloudCoreRadius = 96.0;
        float cloudThickness = 42.0;
        float outerR = cloudCoreRadius + cloudThickness;
        vec3 oc = ro - beaconPos;
        bool cameraInsideCloudSphere = length(oc) < outerR;
        bool suppressOverHand = handLikeForeground && !(insidePetrova || cameraInsideCloudSphere);
        float b = dot(oc, rayDir);
        float c = dot(oc, oc);
        float hOuter = b * b - (c - outerR * outerR);

        #ifdef ENABLE_ADRIAN_ATMOSPHERE
        if (hOuter > 0.0 && !suppressOverHand) {
            float sq = sqrt(hOuter);
            float t0 = -b - sq;
            float t1 = -b + sq;
            float entry = max(t0, 0.0);
            float exit = max(t1, 0.0);
            if (exit > entry && entry < sceneDist) {
                vec3 hit = ro + rayDir * entry;
                float t = frameTimeCounter;
                float swirl = swirlField(hit - beaconPos, t);
                float edge = 1.0 - smoothstep(cloudCoreRadius + 6.0, outerR, length(hit - beaconPos));
                float depthMask = clamp((exit - entry) / cloudThickness, 0.0, 1.0);
                float density = clamp(depthMask * (0.45 + 0.75 * swirl) * (0.7 + edge * 0.3), 0.0, 1.0);
                vec3 cloudCol = mix(vec3(0.14, 0.34, 0.05), vec3(0.62, 0.96, 0.08), swirl);
                if (!cameraInsideCloudSphere) {
                    sceneColor.rgb = cloudCol;
                } else {
                    sceneColor.rgb = mix(sceneColor.rgb, cloudCol, density * 0.72);
                    sceneColor.rgb += cloudCol * density * 0.24;
                }
            }
        }

        if (cameraInsideCloudSphere) {
            if (hasSceneGeometry) {
                vec3 relScene = sceneWorldPos - beaconPos;
                float radial = length(relScene);
                vec3 dirToBorder = normalize(relScene + vec3(1e-5));
                vec3 borderPos = dirToBorder * outerR;

                float borderSwirl = swirlField(borderPos, frameTimeCounter);
                float localSwirl = swirlField(relScene, frameTimeCounter * 0.75);

                float islandMask = 1.0 - smoothstep(cloudCoreRadius * 0.45, cloudCoreRadius * 1.05, radial);
                float borderLight = 0.35 + 0.65 * borderSwirl;
                vec3 interiorGreen = mix(vec3(0.10, 0.34, 0.08), vec3(0.44, 0.96, 0.20), borderLight);

                sceneColor.rgb = mix(sceneColor.rgb, sceneColor.rgb * vec3(0.62, 1.28, 0.70), 0.30 * islandMask);
                sceneColor.rgb = mix(sceneColor.rgb, interiorGreen, (0.16 + 0.22 * localSwirl) * islandMask);
            }

            if (hOuter > 0.0) {
                float tDome = max(-b + sqrt(hOuter), 0.0);
                // Depth-occlude dome so nearby blocks render on top.
                if (tDome > 0.0 && tDome < sceneDist) {
                    vec3 domeHit = ro + rayDir * tDome;
                    float domeSwirl = swirlField(domeHit - beaconPos, frameTimeCounter * 0.95);
                    vec3 domeCol = mix(vec3(0.07, 0.24, 0.05), vec3(0.46, 0.92, 0.16), domeSwirl);
                    float domeAlpha = 0.16 + 0.16 * domeSwirl;
                    sceneColor.rgb = mix(sceneColor.rgb, domeCol, domeAlpha);
                }
            }
        }
        #endif

        #ifdef ENABLE_PETROVA_LINE
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

                vec3 cell = floor(p * 0.22);
                float hr = hash(cell.x * 117.0 + cell.y * 313.0 + cell.z * 71.0);
                if (hr > 0.84) {
                    float twinkle = sin(frameTimeCounter * 10.0 + hr * 23.0 + ang * 5.0) * 0.5 + 0.5;
                    sparkleAmount += localGlow * twinkle * smoothstep(0.84, 1.0, hr);
                }
            }
            t += 8.0;
        }

        if (lineGlow > 0.0 && !suppressOverHand) {
            vec3 lineCol = vec3(1.0, 0.02, 0.02);
            sceneColor.rgb += lineCol * lineGlow * 2.05;
        }
        if (sparkleAmount > 0.0 && !suppressOverHand) {
            vec3 sparkleColor = vec3(1.0, 1.0, 1.0);
            sceneColor.rgb += sparkleColor * min(sparkleAmount * 0.42, 1.5);
        }
        #endif

        #ifdef ENABLE_ASTROPHAGE_SWARM
        if (insidePetrova && !suppressOverHand) {
            float insideStrength = 1.0 - smoothstep(petrovaTubeRadius * 0.45, petrovaTubeRadius * 1.05, camTubeDist);
            vec3 redFog = vec3(0.95, 0.02, 0.04);
            
            sceneColor.rgb = mix(sceneColor.rgb, vec3(sceneColor.r, sceneColor.g * 0.18, sceneColor.b * 0.22), REDSHIFT_POWER * insideStrength);
            sceneColor.rgb = mix(sceneColor.rgb, redFog, (0.34 * REDSHIFT_POWER) * insideStrength);

            float particleAmount = 0.0;
            for (int i = 1; i <= 8; i++) {
                vec3 samplePos = ro + rayDir * (float(i) * 6.0);
                samplePos.y -= frameTimeCounter * 2.0;
                samplePos += vec3(0.0, 0.0, frameTimeCounter * 0.9);

                vec3 cellId = floor(samplePos * 0.75);
                vec3 localPos = fract(samplePos * 0.75) - 0.5;
                float r = hash(cellId.x * 127.0 + cellId.y * 311.0 + cellId.z * 73.0);

                if (r > SWARM_DENSITY) {
                    float dist = length(localPos);
                    float twinkle = sin(frameTimeCounter * 9.0 + r * 25.0) * 0.5 + 0.5;
                    particleAmount += smoothstep(0.22, 0.0, dist) * twinkle;
                }
            }
            sceneColor.rgb += vec3(1.0) * min(particleAmount * 0.55, 1.6) * insideStrength;
        }
        #endif
    }

    color = sceneColor;
}