#![feature(fn_traits)]
#![recursion_limit = "256"]

#[macro_use]
extern crate qmetaobject;
#[macro_use]
extern crate log;
extern crate simplelog;

use cstr::cstr;
use eyre::*;
use ki18n::klocalizedcontext::KLocalizedContext;
use log::LevelFilter;
use qmetaobject::prelude::*;
use simple_logger::SimpleLogger;

mod ui;

const HORIZONTAL_WIDGET_SPACING: f64 = 20.0;
const VERTICAL_WIDGET_SPACING: f64 = 20.0;
const TEXT_BOX_WIDTH: f64 = 200.0;
// const WINDOW_TITLE: LocalizedString<AppState> = LocalizedString::new("Melo Control");

fn main() -> Result<()> {
    qmetaobject::log::init_qt_to_rust();
    SimpleLogger::new()
        .with_level(LevelFilter::Debug)
        .with_utc_timestamps()
        .init()
        .unwrap();

    qml_register_type::<ui::StreamHandler>(cstr!("StreamHandler"), 1, 0, cstr!("StreamHandler"));

    qsyncable_sys::register_qml_types();

    // Create a QML engine from rust
    let mut engine = QmlEngine::new();
    KLocalizedContext::init_from_engine(&engine);

    ui::init_resources();

    engine.load_file("qrc:/src/main.qml".into());
    engine.exec();

    Ok(())
}
