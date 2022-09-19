use qmetaobject::qrc;

qrc!(pub init_resources,
    "src/ui" as "src" {
        "main.qml",
        "CollectionList.qml",
        "SourceGroupList.qml",
        "transform/PreviewTransform.qml",
    },
    "dist" as "dist" {
        "backend.js",
        "diff.js",
    }
);
