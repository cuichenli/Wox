current_flutter_target := if os() == "windows" { "windows" } else if os() == "linux" { "linux" } else if os() == "macos" { "macos" } else { "unknown" }

default:
    @just --list --unsorted

@dev:
    # make sure lefthook installed
    go install github.com/evilmartians/lefthook@latest
    lefthook install -f

    just _build_hosts
    just _build_flutter

@precommit:
    cd Wox.UI.React && pnpm build && cd ..

@plugins:
    # build plugins
    #just _build_dev_nodejs_plugin Wox.Plugin.ProcessKiller ~/.wox/wox-user/plugins

    just _build_dev_nodejs_plugin Wox.Plugin.ProcessKiller ~/icloud/wox/plugins
    just _build_dev_nodejs_plugin_chatgpt Wox.Plugin.Chatgpt ~/icloud/wox/plugins

@ci_plugin:
    cd ci && go run plugin.go

@release target:
    rm -rf Release
    just _build_hosts
    just _build_flutter

    if [ "{{target}}" = "windows" ]; then \
      cd Wox && CGO_ENABLED=1 GOOS=windows GOARCH=amd64 go build -ldflags "-H windowsgui -s -w -X 'wox/util.ProdEnv=true'" -o ../Release/wox-windows-amd64.exe && cd ..; \
      upx --brute Release/wox-windows-amd64.exe; \
    elif [ "{{target}}" = "linux" ]; then \
      cd Wox && CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -X 'wox/util.ProdEnv=true'" -o ../Release/wox-linux-amd64 && cd ..; \
      upx --brute Release/wox-linux-amd64; \
      chmod +x Release/wox-linux-amd64; \
    elif [ "{{target}}" = "darwin-arm64" ]; then \
      cd Wox && CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 CGO_CFLAGS="-mmacosx-version-min=10.15" CGO_LDFLAGS="-mmacosx-version-min=10.15" go build -ldflags "-s -w -X 'wox/util.ProdEnv=true'" -o ../Release/wox-mac-arm64 && cd ..; \
      just _bundle_mac_app wox-mac-arm64; \
    elif [ "{{target}}" = "darwin-amd64" ]; then \
      cd Wox && CGO_ENABLED=1 GOOS=darwin GOARCH=amd64 CGO_CFLAGS="-mmacosx-version-min=10.15" CGO_LDFLAGS="-mmacosx-version-min=10.15" go build -ldflags "-s -w -X 'wox/util.ProdEnv=true'" -o ../Release/wox-mac-amd64 && cd ..; \
      just _bundle_mac_app wox-mac-amd64; \
    fi

@_bundle_mac_app name:
    chmod +x Release/{{name}}

    # bundle mac app, https://github.com/sindresorhus/create-dmg
    cd Release && \
    rm -rf {{name}}.app && \
    rm -rf Wox.app && \
    mkdir -p {{name}}.app/Contents/MacOS && \
    mkdir -p {{name}}.app/Contents/Resources && \
    cp {{name}} {{name}}.app/Contents/MacOS/wox && \
    cp ../Assets/Info.plist {{name}}.app/Contents/Info.plist && \
    cp ../Assets/app.icns {{name}}.app/Contents/Resources/app.icns && \
    mv {{name}}.app Wox.app && \
    create-dmg Wox.app && \
    mv "Wox 2.0.0.dmg" {{name}}.dmg

@test:
    cd Wox && go test ./...

@_build_dev_nodejs_plugin pluginName directory:
    rm -rf {{directory}}/{{pluginName}}
    cd Plugins/{{pluginName}} && pnpm install && pnpm run build && cd ..
    mkdir -p {{directory}}/{{pluginName}}
    cp -r Plugins/{{pluginName}}/dist/* {{directory}}/{{pluginName}}/
    cp Plugins/{{pluginName}}/plugin.json {{directory}}/{{pluginName}}/plugin.json
    cp -r Plugins/{{pluginName}}/images {{directory}}/{{pluginName}}/images

@_build_dev_nodejs_plugin_chatgpt pluginName directory:
    rm -rf {{directory}}/{{pluginName}}
    cd Plugins/{{pluginName}} && just build && cd ..
    mkdir -p {{directory}}/{{pluginName}}
    cp -r Plugins/{{pluginName}}/dist/* {{directory}}/{{pluginName}}/
    cp Plugins/{{pluginName}}/Wox.Plugin.Chatgpt.Server/plugin.json {{directory}}/{{pluginName}}/plugin.json
    cp -r Plugins/{{pluginName}}/Wox.Plugin.Chatgpt.Server/images {{directory}}/{{pluginName}}/images

@_build_hosts:
    # build hosts
    rm -rf Wox/resource/hosts
    mkdir Wox/resource/hosts
    just _build_nodejs_host Wox/resource/hosts
    just _build_python_host Wox/resource/hosts

@_build_electron:
    cd Wox.UI.React && pnpm install && pnpm build && cd ..

    # electron
    rm -rf Wox/resource/ui/electron
    mkdir -p Wox/resource/ui/electron
    cp Wox.UI.Electron/main.js Wox/resource/ui/electron/main.js
    cp Wox.UI.Electron/preload.js Wox/resource/ui/electron/preload.js

@_build_flutter:
    # flutter
    cd Wox.UI.Flutter/wox && flutter clean && flutter build {{current_flutter_target}} && cd ..
    rm -rf Wox/resource/ui/flutter
    mkdir -p Wox/resource/ui/flutter

    if [ "{{current_flutter_target}}" = "windows" ]; then \
      cp -r Wox.UI.Flutter/wox/build/{{current_flutter_target}}/x64/runner/Release Wox/resource/ui/flutter/wox; \
    elif [ "{{current_flutter_target}}" = "linux" ]; then \
      cp -r Wox.UI.Flutter/wox/build/{{current_flutter_target}}/x64/release/bundle Wox/resource/ui/flutter/wox; \
    elif [ "{{current_flutter_target}}" = "macos" ]; then \
      cp -r Wox.UI.Flutter/wox/build/{{current_flutter_target}}/Build/Products/Release/wox.app Wox/resource/ui/flutter; \
      chmod +x Wox/resource/ui/flutter/wox.app/Contents/MacOS/wox; \
    fi

@_build_nodejs_host directory:
    cd Wox.Plugin.Host.Nodejs && pnpm install && pnpm run build && cd ..
    mkdir -p {{directory}}
    cp Wox.Plugin.Host.Nodejs/dist/index.js {{directory}}/node-host.js

@_build_python_host directory:
    cd Wox.Plugin.Host.Python && \
    rm -rf python-host && \
    rm -rf python-host.pyz && \
    python3 -m pip install -r requirements.txt --target python-host && \
    cp *.py python-host && \
    python3 -m zipapp -p "interpreter" python-host && \
    rm -rf python-host && \
    cd ..
    mkdir -p {{directory}}
    cp Wox.Plugin.Host.Python/python-host.pyz {{directory}}/python-host.pyz