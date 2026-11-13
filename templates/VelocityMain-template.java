package com.${AUTHOR}.${PROJECT_NAME};

import com.google.inject.Inject;
import com.velocitypowered.api.event.Subscribe;
import com.velocitypowered.api.event.proxy.ProxyInitializeEvent;
import com.velocitypowered.api.plugin.Plugin;
import org.slf4j.Logger;

@Plugin(id = "${PLUGIN_ID}", name = "${PROJECT_NAME}", version = "${PLUGIN_VERSION}")
public final class Main {

    private final Logger logger;

    @Inject
    public Main(Logger logger) {
        this.logger = logger;
    }

    @Subscribe
    public void onProxyInitialization(ProxyInitializeEvent event) {
        logger.info("{} has been enabled", "${PROJECT_NAME}");
    }
}
