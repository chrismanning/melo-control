#![feature(exit_status_error)]

use std::process::{Command, Stdio};
use eyre::*;

pub fn main() -> Result<()> {
    println!("cargo:rerun-if-changed=package.json");
    println!("cargo:rerun-if-changed=babel.config.json");
    println!("cargo:rerun-if-changed=webpack.config.json");

    // npm ci
    Command::new("npm")
        .arg("ci")
        .stdout(Stdio::null())
        .status()?
        .exit_ok()?;

    // npm run build
    Command::new("npm")
        .arg("run")
        .arg("build")
        .stdout(Stdio::null())
        .status()?
        .exit_ok()?;

    Ok(())
}
