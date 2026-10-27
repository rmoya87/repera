// Compatibility source for previously generated Repera.xcodeproj files.
//
// The iCloud route archive and backup actor are now declared in
// LiveActivityView.swift, which has always been included in the Repera
// target's Compile Sources phase. Do not redeclare them here: older
// generated projects may compile this file while newer ones also compile
// LiveActivityView.swift.
//
// Keep this file checked in until existing Xcode project references have
// naturally migrated. No implementation belongs in this compatibility stub.
