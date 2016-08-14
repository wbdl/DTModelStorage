//
//  RealmStorageTestCase.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 02.01.16.
//  Copyright © 2016 Denys Telezhkin. All rights reserved.
//

import UIKit
import XCTest
@testable import DTModelStorage
import Nimble
import RealmSwift

func delay(_ delay:Double, _ closure:()->()) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

class RealmStorageTestCase: XCTestCase {
    
    let realm = { Void -> Realm in
        let configuration = Realm.Configuration(fileURL: nil, inMemoryIdentifier: "foo")
        return try! Realm(configuration: configuration)
    }()
    var storage: RealmStorage!
    
    override func setUp() {
        super.setUp()
        storage = RealmStorage()
        try! realm.write {
            realm.deleteAllObjects()
        }
    }
    
    func addDogNamed(_ name: String) {
        try! realm.write {
            let dog = Dog()
            dog.name = name
            realm.add(dog)
        }
    }
    
    func testRealmStorageHandlesSectionAddition() {
        addDogNamed("Rex")
        
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        expect((self.storage.itemAtIndexPath(indexPath(0, 0)) as? Dog)?.name) == "Rex"
    }
    
    func testRealmStorageIsAbleToHandleRealmNotification() {
        let storageObserver = StorageUpdatesObserver()
        storage.delegate = storageObserver
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        addDogNamed("Rex")
        
        expect((self.storage.itemAtIndexPath(indexPath(0, 0)) as? Dog)?.name) == "Rex"
        expect(storageObserver.storageNeedsReloadingFlag) == true
    }
    
    func testInsertNotificationIsHandled() {
        let updateObserver = StorageUpdatesObserver()
        storage.delegate = updateObserver
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        addDogNamed("Rex")
        
        expect((self.storage.itemAtIndexPath(indexPath(0, 0)) as? Dog)?.name) == "Rex"
        
        delay(0.1) {
            try! self.realm.write {
                let dog = Dog()
                dog.name = "Rexxar"
                self.realm.add(dog)
            }
        }
        expect(updateObserver.update?.insertedRowIndexPaths).toEventually(equal(Set([indexPath(1, 0)])))
    }
    
    func testDeleteNotificationIsHandled() {
        let updateObserver = StorageUpdatesObserver()
        storage.delegate = updateObserver
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        var dog: Dog!
        try! realm.write {
            dog = Dog()
            dog.name = "Rexxar"
            realm.add(dog)
        }
        
        delay(0.1) {
            try! self.realm.write {
                self.realm.delete(dog)
            }
        }
        expect(updateObserver.update?.deletedRowIndexPaths).toEventually(equal(Set([indexPath(0, 0)])))
    }
    
    func testUpdateNotificationIsHandled() {
        let updateObserver = StorageUpdatesObserver()
        storage.delegate = updateObserver
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        var dog: Dog!
        try! realm.write {
            dog = Dog()
            dog.name = "Rexxar"
            realm.add(dog)
        }
        delay(0.1) {
            try! self.realm.write {
                dog.name = "Rex"
            }
        }
        expect(updateObserver.update?.updatedRowIndexPaths).toEventually(equal(Set([indexPath(0, 0)])))
    }
    
    func testStorageHasSingleSection() {
        addDogNamed("Rex")
        
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        
        let section = storage.sectionAtIndex(0)
        
        expect(section?.numberOfItems) == 1
        expect((section?.items.first as? Dog)?.name) == "Rex"
    }
    
    func testItemAtIndexPathIsSafe() {
        let item = storage.itemAtIndexPath(indexPath(0, 0))
        expect(item).to(beNil())
        let section = storage.sectionAtIndex(0)
        expect(section).to(beNil())
    }
    
    func testDeletingSectionsTriggersUpdates() {
        addDogNamed("Rex")
        addDogNamed("Barnie")
        
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        
        let observer = StorageUpdatesObserver()
        storage.delegate = observer
        
        storage.deleteSections(IndexSet(integer: 0))
        expect(observer.update?.deletedSectionIndexes) == Set<Int>([0])
        expect(self.storage.sections.count) == 1
    }
    
    func testShouldDeleteSectionsEvenIfThereAreNone()
    {
        storage.deleteSections(IndexSet(integer: 0))
    }
    
    func testSetSectionShouldAddWhenThereAreNoSections() {
        addDogNamed("Rex")
        addDogNamed("Barnie")
        
        storage.setSectionWithResults(realm.allObjects(ofType: Dog.self), forSectionIndex: 0)
        
        expect(self.storage.sections.count) == 1
        expect(self.storage.sectionAtIndex(0)?.items.count) == 2
    }
    
    func testSectionShouldBeReplaced() {
        addDogNamed("Rex")
        addDogNamed("Barnie")
        
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.setSectionWithResults(realm.allObjects(ofType: Dog.self), forSectionIndex: 0)
        
        expect(self.storage.sections.count) == 1
        expect(self.storage.sectionAtIndex(0)?.items.count) == 2
    }
    
    func testShouldDisallowSettingWrongSection() {
        storage.setSectionWithResults(realm.allObjects(ofType: Dog.self), forSectionIndex: 5)
        
        expect(self.storage.sections.count) == 0
    }
    
    func testSupplementaryHeadersWork() {
        storage.configureForTableViewUsage()
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.setSectionHeaderModels([1,2,3])
        
        expect(self.storage.headerModelForSectionIndex(2) as? Int) == 3
        expect(self.storage.supplementaryModelOfKind(DTTableViewElementSectionHeader, sectionIndexPath: IndexPath(item:0, section: 3))).to(beNil())
    }
    
    func testSupplementaryFootersWork() {
        storage.configureForTableViewUsage()
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.setSectionFooterModels([1,2,3])
        
        expect(self.storage.footerModelForSectionIndex(2) as? Int) == 3
        expect(self.storage.supplementaryModelOfKind(DTTableViewElementSectionFooter, sectionIndexPath: IndexPath(item:0, section: 3))).to(beNil())
    }
    
    func testSupplementariesCanBeClearedOut() {
        storage.configureForTableViewUsage()
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.setSectionFooterModels([1,2,3])
        
        storage.setSupplementaries([[IndexPath:[Int]]]().flatMap { $0 }, forKind: DTTableViewElementSectionFooter)
        expect(self.storage.supplementaryModelOfKind(DTTableViewElementSectionFooter, sectionIndexPath: IndexPath(item:0, section: 0))).to(beNil())
    }
    
    func testSettingSupplementaryModelForSectionIndex() {
        storage.configureForTableViewUsage()
        storage.addSectionWithResults(realm.allObjects(ofType: Dog.self))
        storage.setSectionHeaderModel(1, forSectionIndex: 0)
    
        expect(self.storage.headerModelForSectionIndex(0) as? Int) == 1
        
        storage.setSectionFooterModel(2, forSectionIndex: 0)
        
        expect(self.storage.footerModelForSectionIndex(0) as? Int) == 2
    }
    
    func testSectionModelIsAwareOfItsLocation() {
        addDogNamed("Rex")
        
        let results = realm.allObjects(ofType: Dog.self)
        storage.addSectionWithResults(results)
        
        let section = storage.sectionAtIndex(0)! as? RealmSection<Dog>
        expect(section?.currentSectionIndex) == 0
    }
}
