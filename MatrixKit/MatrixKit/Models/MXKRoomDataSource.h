/*
 Copyright 2015 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <UIKit/UIKit.h>

#import "MXKDataSource.h"
#import "MXKRoomBubbleCellData.h"
#import "MXKEventFormatter.h"

/**
 Identifier to use for cells that display incoming room events, ie events
 that have not been sent by the user.
 */
extern NSString *const kMXKIncomingRoomBubbleCellIdentifier;

/**
 Identifier to use for cells that display outgoing room events, ie events
 that have been sent by the user.
 */
extern NSString *const kMXKOutgoingRoomBubbleCellIdentifier;


/**
 The data source for `MXKRoomViewController`.
 */
@interface MXKRoomDataSource : MXKDataSource <UITableViewDataSource> {

@protected

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    NSMutableArray *bubbles;    // roomItems??

    /**
     The queue to process room messages.
     This processing can consume time. Handling it on a separated thread avoids to block the main thread.
     */
    dispatch_queue_t processingQueue;

    /**
     The queue of events that need to be processed in order to compute their display.
     */
    NSMutableArray *eventsToProcess;
}

/**
 The room the data comes from.
 */
@property (nonatomic, readonly) MXRoom *room;


#pragma mark - Configuration
/**
 The type of events to display as messages.
 */
@property (nonatomic) NSArray *eventsFilterForMessages;

/**
 The events to display texts formatter.
 `MXKRoomBubbleCellDataStoring` instances can use it to format text.
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;

/**
 Flag to not list redacted events in the messages list.
 */
@property (nonatomic) BOOL hideRedactions;

/**
 Flag to not list unsupported events in the messages list.
 */
@property (nonatomic) BOOL hideUnsupportedEvents;


#pragma mark - Life cycle
/**
 Initialise the data source to serve data corresponding to the passed room.
 
 @param room the room to get data from.
 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithRoom:(MXRoom *)aRoom andMatrixSession:(MXSession*)mxSession;

/**
 Load more messages from the history.
 
 @param numItems the number of items to get.
 @param success a block called when the operation succeeds.
 @param failure a block called when the operation fails.
 */
- (void)paginateBackMessages:(NSUInteger)numItems success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Load enough messages to fill the rect.
 
 @param the rect to fill.
 @param success a block called when the operation succeeds.
 @param failure a block called when the operation fails.
 */
- (void)paginateBackMessagesToFillRect:(CGRect)rect success:(void (^)())success failure:(void (^)(NSError *error))failure;

@end
