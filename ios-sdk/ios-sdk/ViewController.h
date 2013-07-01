//
//  ViewController.h
//  ios-sdk
//
//  Created by Javier Alvarez on 6/29/13.
//  Copyright (c) 2013 Javier Alvarez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MLMeli.h"

@interface ViewController : UIViewController <MLMeliDelegate>

@property (weak, nonatomic) IBOutlet UILabel *responseLabel;
@property (weak, nonatomic) IBOutlet UITextField *codeText;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)getAuthURL:(id)sender;
- (IBAction)authorize:(id)sender;
- (IBAction)doRefreshAccessToken:(id)sender;
- (IBAction)doGet:(id)sender;
- (IBAction)doPost:(id)sender;
- (IBAction)doPut:(id)sender;
- (IBAction)doDelete:(id)sender;


@end
