package com.${AUTHOR}.${PROJECT_NAME};

import com.${AUTHOR}.${PROJECT_NAME}.managers.CommandManager;
import com.${AUTHOR}.${PROJECT_NAME}.managers.ConfigManager;
import com.${AUTHOR}.${PROJECT_NAME}.managers.EventManager;

import dev.jorel.commandapi.CommandAPI;
import dev.jorel.commandapi.CommandAPIBukkitConfig;
import lombok.Getter;

import com.${AUTHOR}.Utils.CommandUtils;
import com.${AUTHOR}.Utils.MessageUtils;

import org.bukkit.plugin.java.JavaPlugin;

@Getter
public final class Main extends JavaPlugin {

    private ConfigManager configManager;
    private CommandManager commandManager;
    private EventManager eventManager;

    @Override
    public void onLoad() {
        CommandAPI.onLoad(new CommandAPIBukkitConfig(this));
    }

    @Override
    public void onEnable() {
        saveDefaultConfig();
        CommandAPI.onEnable();

        this.configManager = new ConfigManager(this);
        this.commandManager = new CommandManager(this);
        this.eventManager = new EventManager(this);

        CommandUtils.setPlugin(this);
        MessageUtils.sendStartupMessage(this);

    }

    @Override
    public void onDisable() {
        CommandAPI.onDisable();
        MessageUtils.sendShutdownMessage(this);
    }

}