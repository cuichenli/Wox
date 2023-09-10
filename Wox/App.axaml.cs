using System;
using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using Wox.Core;
using Wox.Core.Plugin;
using Wox.Core.Utils;
using Wox.ViewModels;
using Wox.Views;

namespace Wox;

public class App : Application
{
    public override void Initialize()
    {
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop)
            desktop.MainWindow = new MainWindow
            {
                DataContext = new MainWindowViewModel()
            };

        base.OnFrameworkInitializationCompleted();

        Bootstrap();
    }


    /// <summary>
    /// </summary>
    private void Bootstrap()
    {
        DataLocation.EnsureDirectoryExist();
        Logger.Info("---------------------------");
        Logger.Info("Bootstrap Wox");
        Logger.Info($"CLR version: {Environment.Version}");
#if DEBUG
        Logger.Info("Run Mode: Debug");
#else
        Logger.Info("Run Mode: Release");
#endif

        PluginManager.LoadPlugins(new PublicAPIInstance()).Wait();

        Logger.Info("Finish bootstrap");
    }
}