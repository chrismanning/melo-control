use eyre::*;
use kconfig::ksharedconfig::KSharedConfigPtr;
use kconfig::prelude::*;
use qmetaobject::prelude::*;
use qmetaobject::{QStandardPathLocation, QUrl};

#[derive(QObject)]
pub struct Config {
    base: qt_base_class!(trait QObject),
    config: KSharedConfigPtr,
    server_url: qt_property!(QUrl; NOTIFY server_url_changed),
    server_url_changed: qt_signal!(server_url: QUrl),
    sync: qt_method!(fn sync(&self) {
        warn!("sync() called");
    }),
}

impl Default for Config {
    fn default() -> Self {
        let mut config = KConfig::new("melorc", OpenFlags::FULL_CONFIG, QStandardPathLocation::ConfigLocation);
        let server_url = config.group("server")
            .read_qstring_entry("url")
            .expect("config property 'server.url' not found");
        debug!("server.url: {}", &server_url);
        let server_url = QUrl::from_user_input(server_url);
        let config = KSharedConfigPtr::new(config);
        // TODO on_server_url_changed write to melorc
        Config {
            base: Default::default(),
            config,
            server_url,
            server_url_changed: Default::default(),
            sync: Default::default(),
        }
    }
}
