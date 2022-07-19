use qmetaobject::qrc;

qrc!(pub init_resources,
    "src/ui" as "src" {
        "main.qml",
    },
    "dist" as "dist" {
        "backend.js",
    }
);
