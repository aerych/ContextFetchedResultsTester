//
//  ViewController.m
//  ContextFetchedResultsTester
//
//  Created by aerych on 8/15/15.
//  Copyright (c) 2015 aerych. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "Item.h"

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, readonly) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;
@property (nonatomic, strong) NSManagedObjectContext *resultsContext;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self deleteOldData];
    [self setupStartingData];
    
    [self createManagedObjectContexts];
    [self createResultsController];
    
    NSError *error;
    [self.resultsController performFetch:&error];
    
//    [self testChangeOnBackgroundContext];
    [self testDeleteOnBackgroundContext];
}

- (void)testDeleteOnBackgroundContext
{
    //
    //  Check results context at the start
    //
//    [self inspectResults];
    NSLog(@" ");


    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]];
        NSError *error;
        NSArray *results = [self.backgroundContext executeFetchRequest:fetchRequest error:&error];


        //
        // Edit one item on the background context
        //
        NSManagedObject *obj = results.firstObject;
        [self.backgroundContext deleteObject:obj];


        //
        // Save the background and main contexts
        //
        [self.backgroundContext save:&error];

    }];

    NSLog(@" ");
    NSLog(@"Saving main context");
    NSLog(@" ");
    [self.mainContext performBlockAndWait:^{
        NSError *error;
        [self.mainContext save:&error];
    }];


    //
    //  Check results context
    //
    [self inspectResults];
    NSLog(@" ");


    //
    //  Reset results context
    //
    NSLog(@" ");
    NSLog(@"Resetting");
    NSLog(@" ");
    [self.resultsContext reset];

    // Must performFetch after resetting.
    NSError *error;
    [self.resultsController performFetch:&error];


    //
    //  Check results context again
    //
    [self inspectResults];
    NSLog(@" ");
    
}

- (void)testChangeOnBackgroundContext
{
    //
    //  Check results context at the start
    //
    [self inspectResults];
    NSLog(@" ");
    
    
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]];
        NSError *error;
        NSArray *results = [self.backgroundContext executeFetchRequest:fetchRequest error:&error];

        
        //
        // Edit one item on the background context
        //
        NSManagedObject *obj = results.firstObject;
        Item *item = (Item *)[self.backgroundContext existingObjectWithID:obj.objectID error:&error];
        item.name = [NSString stringWithFormat:@"%@ changed", item.name];
        
        
        //
        // Save the background and main contexts
        //
        [self.backgroundContext save:&error];

    }];
    
    NSLog(@" ");
    NSLog(@"Saving main context");
    NSLog(@" ");
    [self.mainContext performBlockAndWait:^{
        NSError *error;
        [self.mainContext save:&error];
    }];
    
    
    //
    //  Check results context
    //
    [self inspectResults];
    NSLog(@" ");
    
    
    //
    //  Reset results context
    //
    NSLog(@" ");
    NSLog(@"Resetting");
    NSLog(@" ");
    [self.resultsContext reset];
    
    
    //
    //  Check results context again
    //
    [self inspectResults];
    NSLog(@" ");
    
}


- (void)inspectResults
{
    for (Item *item in self.resultsController.fetchedObjects) {
        NSLog(@"Item: %@", item.name);
    }
}

- (void)createManagedObjectContexts
{
    self.backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.backgroundContext.parentContext = self.mainContext;
    
    self.resultsContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.resultsContext.parentContext = self.mainContext;
}

- (void)createResultsController
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]];
    self.resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                 managedObjectContext:self.resultsContext
                                                                   sectionNameKeyPath:nil
                                                                            cacheName:nil];
    self.resultsController.delegate = self;
}

- (NSManagedObjectContext *)mainContext
{
    AppDelegate *appDelegate =  (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.managedObjectContext;
}

- (void)setupStartingData
{
    NSArray *items = @[@"A", @"B", @"C", @"D", @"E"];
    
    NSManagedObjectContext *context = self.mainContext;
    for (NSString *name in items) {
        Item *item = [NSEntityDescription insertNewObjectForEntityForName:@"Item"
                                                     inManagedObjectContext:context];
        item.name = name;
    }

    [context performBlockAndWait:^{
        NSError *error;
        [context save:&error];
    }];
}

- (void)deleteOldData
{
    NSManagedObjectContext *context = self.mainContext;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Item"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO]];
    NSError *error;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *obj in results) {
        [context deleteObject:obj];
    }

    [context performBlockAndWait:^{
        NSError *error;
        [context save:&error];
    }];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@" ");
}

@end
