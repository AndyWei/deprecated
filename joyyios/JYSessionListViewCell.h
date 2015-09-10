//
//  JYSessionListViewCell.h
//  joyyios
//
//  Created by Ping Yang on 9/3/15.
//  Copyright (c) 2015 Joyy Inc. All rights reserved.
//

@interface JYSessionListViewCell : UITableViewCell

@property (nonatomic) XMPPMessageArchiving_Contact_CoreDataObject *contact;
@property (nonatomic, readonly) JYPerson *person;

@end
