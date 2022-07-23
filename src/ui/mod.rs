use qmetaobject::qrc;

qrc!(pub init_resources,
    "src/ui" as "src" {
        "main.qml",
        "CollectionList.qml",
    },
    "dist" as "dist" {
        "backend.js",
    }
);
