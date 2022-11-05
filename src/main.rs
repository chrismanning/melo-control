#![feature(fn_traits)]
#![recursion_limit = "256"]

#[macro_use]
extern crate qmetaobject;
#[macro_use]
extern crate log;
extern crate simplelog;

use cstr::cstr;
use eyre::*;
use kconfig::prelude::*;
use ki18n::klocalizedcontext::KLocalizedContext;
use log::LevelFilter;
use qmetaobject::prelude::*;
use qmetaobject::{qml_register_singleton_instance, QStandardPathLocation};
use simple_logger::SimpleLogger;

mod ui;
mod config;

fn main() -> Result<()> {
    qmetaobject::log::init_qt_to_rust();
    SimpleLogger::new()
        .with_level(LevelFilter::Debug)
        .with_utc_timestamps()
        .init()?;

    let app_config = config::Config::default();

    qml_register_singleton_instance::<config::Config>(cstr!("app.melo.Config"), 1, 0, cstr!("Config"), app_config);
    qml_register_type::<ui::StreamHandler>(cstr!("app.melo.StreamHandler"), 1, 0, cstr!("StreamHandler"));

    qsyncable_sys::register_qml_types();

    let mut engine = QmlEngine::new();
    KLocalizedContext::init_from_engine(&engine);

    ui::init_resources();

    engine.load_file("qrc:/ui/main.qml".into());
    engine.exec();

    Ok(())
}
