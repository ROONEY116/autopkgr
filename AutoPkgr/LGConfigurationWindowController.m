//
//  LGConfigurationWindowController.m
//  AutoPkgr
//
//  Created by James Barclay on 6/26/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import "LGConfigurationWindowController.h"
#import "LGConstants.h"
#import "LGEmailer.h"
#import "LGHostInfo.h"
#import "LGAutoPkgRunner.h"
#import "LGGitHubJSONLoader.h"
#import "LGVersionComparator.h"
#import "SSKeychain.h"

@interface LGConfigurationWindowController ()

@end

@implementation LGConfigurationWindowController

@synthesize smtpTo;
@synthesize smtpServer;
@synthesize smtpUsername;
@synthesize smtpPassword;
@synthesize smtpPort;
@synthesize smtpFrom;
@synthesize autoPkgRunInterval;
@synthesize repoURLToAdd;
@synthesize localMunkiRepo;
@synthesize smtpAuthenticationEnabledButton;
@synthesize smtpTLSEnabledButton;
@synthesize warnBeforeQuittingButton;
@synthesize checkForNewVersionsOfAppsAutomaticallyButton;
@synthesize checkForRepoUpdatesAutomaticallyButton;
@synthesize sendEmailNotificationsWhenNewVersionsAreFoundButton;
@synthesize autoPkgCacheFolderButton;
@synthesize autoPkgRecipeReposFolderButton;
@synthesize localMunkiRepoFolderButton;
@synthesize sendTestEmailButton;
@synthesize installGitButton;
@synthesize installAutoPkgButton;
@synthesize gitStatusLabel;
@synthesize autoPkgStatusLabel;
@synthesize gitStatusIcon;
@synthesize autoPkgStatusIcon;
@synthesize sendTestEmailStatus;
@synthesize sendTestEmailSpinner;
@synthesize testSmtpServerSpinner;
@synthesize testSmtpServerStatus;

static void *XXCheckForNewAppsAutomaticallyEnabledContext = &XXCheckForNewAppsAutomaticallyEnabledContext;
static void *XXCheckForRepoUpdatesAutomaticallyEnabledContext = &XXCheckForRepoUpdatesAutomaticallyEnabledContext;
static void *XXEmailNotificationsEnabledContext = &XXEmailNotificationsEnabledContext;
static void *XXAuthenticationEnabledContext = &XXAuthenticationEnabledContext;

- (void)dealloc
{
    [smtpAuthenticationEnabledButton removeObserver:self forKeyPath:@"cell.state" context:XXAuthenticationEnabledContext];
    [sendEmailNotificationsWhenNewVersionsAreFoundButton removeObserver:self forKeyPath:@"cell.state" context:XXEmailNotificationsEnabledContext];
    [checkForNewVersionsOfAppsAutomaticallyButton removeObserver:self forKeyPath:@"cell.state" context:XXCheckForNewAppsAutomaticallyEnabledContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        defaults = [NSUserDefaults standardUserDefaults];
        NSNotificationCenter *ndc = [NSNotificationCenter defaultCenter];
        [ndc addObserver:self selector:@selector(startProgressNotificationReceived:) name:kProgressStartNotification object:nil];
        [ndc addObserver:self selector:@selector(stopProgressNotificationReceived:) name:kProgressStopNotification object:nil];
        [ndc addObserver:self selector:@selector(updateProgressNotificationReceived:) name:kProgressMessageUpdateNotification object:nil];
    }
    return self;
}

- (void)awakeFromNib
{
    [smtpAuthenticationEnabledButton addObserver:self
                                      forKeyPath:@"cell.state"
                                         options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                         context:XXAuthenticationEnabledContext];

    [sendEmailNotificationsWhenNewVersionsAreFoundButton addObserver:self
                                                          forKeyPath:@"cell.state"
                                                             options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                                             context:XXEmailNotificationsEnabledContext];

    [checkForNewVersionsOfAppsAutomaticallyButton addObserver:self
                                                   forKeyPath:@"cell.state"
                                                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                                      context:XXCheckForNewAppsAutomaticallyEnabledContext];

    // Set up buttons to save their defaults
    [smtpTLSEnabledButton setTarget:self];
    [smtpTLSEnabledButton setAction:@selector(changeTLSButtonState)];
    [warnBeforeQuittingButton setTarget:self];
    [warnBeforeQuittingButton setAction:@selector(changeWarnBeforeQuittingButtonState)];
    [smtpAuthenticationEnabledButton setTarget:self];
    [smtpAuthenticationEnabledButton setAction:@selector(changeSmtpAuthenticationButtonState)];
    [sendEmailNotificationsWhenNewVersionsAreFoundButton setTarget:self];
    [sendEmailNotificationsWhenNewVersionsAreFoundButton setAction:@selector(changeSendEmailNotificationsWhenNewVersionsAreFoundButtonState)];
    [checkForNewVersionsOfAppsAutomaticallyButton setTarget:self];
    [checkForNewVersionsOfAppsAutomaticallyButton setAction:@selector(changeCheckForNewVersionsOfAppsAutomaticallyButtonState)];
    [checkForRepoUpdatesAutomaticallyButton setTarget:self];
    [checkForRepoUpdatesAutomaticallyButton setAction:@selector(changeCheckForRepoUpdatesAutomaticallyButtonState)];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == XXAuthenticationEnabledContext) {
        if ([keyPath isEqualToString:@"cell.state"]) {
            if ([[change objectForKey:@"new"] integerValue] == 1) {
                [smtpUsername setEnabled:YES];
                [smtpPassword setEnabled:YES];
                [smtpTLSEnabledButton setEnabled:YES];
            } else {
                [smtpUsername setEnabled:NO];
                [smtpPassword setEnabled:NO];
                [smtpTLSEnabledButton setEnabled:NO];
            }
        }
    } else if (context == XXEmailNotificationsEnabledContext) {
        if ([keyPath isEqualToString:@"cell.state"]) {
            if ([[change objectForKey:@"new"] integerValue] == 1) {
                [smtpTo setEnabled:YES];
                [smtpServer setEnabled:YES];
                [smtpUsername setEnabled:YES];
                [smtpPassword setEnabled:YES];
                [smtpPort setEnabled:YES];
                [smtpAuthenticationEnabledButton setEnabled:YES];
                [smtpTLSEnabledButton setEnabled:YES];
                [sendTestEmailButton setEnabled:YES];
                [smtpFrom setEnabled:YES];
            } else {
                [smtpTo setEnabled:NO];
                [smtpServer setEnabled:NO];
                [smtpUsername setEnabled:NO];
                [smtpPassword setEnabled:NO];
                [smtpPort setEnabled:NO];
                [smtpAuthenticationEnabledButton setEnabled:NO];
                [smtpTLSEnabledButton setEnabled:NO];
                [sendTestEmailButton setEnabled:NO];
                [smtpFrom setEnabled:NO];
            }
        }
    } else if (context == XXCheckForNewAppsAutomaticallyEnabledContext) {
        if ([keyPath isEqualToString:@"cell.state"]) {
            if ([[change objectForKey:@"new"] integerValue] == 1) {
                [autoPkgRunInterval setEnabled:YES];
            } else {
                [autoPkgRunInterval setEnabled:NO];
            }
        }
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Populate the preference values from the user defaults if they exist

    if ([defaults objectForKey:kAutoPkgRunInterval]) {
        [autoPkgRunInterval setIntegerValue:[defaults integerForKey:kAutoPkgRunInterval]];
    }
    if ([defaults objectForKey:kLocalMunkiRepoPath]) {
        [localMunkiRepo setStringValue:[defaults objectForKey:kLocalMunkiRepoPath]];
    }
    if ([defaults objectForKey:kSMTPServer]) {
        [smtpServer setStringValue:[defaults objectForKey:kSMTPServer]];
    }
    if ([defaults objectForKey:kSMTPFrom]) {
        [smtpFrom setStringValue:[defaults objectForKey:kSMTPFrom]];
    }
    if ([defaults integerForKey:kSMTPPort]) {
        [smtpPort setIntegerValue:[defaults integerForKey:kSMTPPort]];
    }
    if ([defaults objectForKey:kSMTPUsername]) {
        [smtpUsername setStringValue:[defaults objectForKey:kSMTPUsername]];
    }
    if ([defaults objectForKey:kSMTPTo]) {
        NSMutableArray *to = [[NSMutableArray alloc] init];
        for (NSString *toAddress in [defaults objectForKey:kSMTPTo]) {
            if (![toAddress isEqual:@""]) {
                [to addObject:toAddress];
            }
        }
        [smtpTo setObjectValue:to];
    }
    if ([defaults objectForKey:kSMTPTLSEnabled]) {
        [smtpTLSEnabledButton setState:[[defaults objectForKey:kSMTPTLSEnabled] boolValue]];
    }
    if ([defaults objectForKey:kSMTPAuthenticationEnabled]) {
        [smtpAuthenticationEnabledButton setState:[[defaults objectForKey:kSMTPAuthenticationEnabled] boolValue]];
    }
    if ([defaults objectForKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled]) {
        [sendEmailNotificationsWhenNewVersionsAreFoundButton setState:[[defaults objectForKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled] boolValue]];
    }
    if ([defaults objectForKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled]) {
        [checkForNewVersionsOfAppsAutomaticallyButton setState:[[defaults objectForKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled] boolValue]];
    }
    if ([defaults objectForKey:kCheckForRepoUpdatesAutomaticallyEnabled]) {
        [checkForRepoUpdatesAutomaticallyButton setState:[[defaults objectForKey:kCheckForRepoUpdatesAutomaticallyEnabled] boolValue]];
    }
    if ([defaults objectForKey:kWarnBeforeQuittingEnabled]) {
        [warnBeforeQuittingButton setState:[[defaults objectForKey:kWarnBeforeQuittingEnabled] boolValue]];
    }

    // Read the SMTP password from the keychain and populate in
    // NSSecureTextField if it exists
    NSError *error = nil;
    NSString *smtpUsernameString = [defaults objectForKey:kSMTPUsername];

    if (smtpUsernameString) {
        NSString *password = [SSKeychain passwordForService:kApplicationName
                                                    account:smtpUsernameString
                                                      error:&error];

        if ([error code] == SSKeychainErrorNotFound) {
            NSLog(@"Keychain item not found for account %@.", smtpUsernameString);
        } else if ([error code] == SSKeychainErrorNoPassword) {
            NSLog(@"Found the keychain item for %@ but no password value was returned.", smtpUsernameString);
        } else if (error != nil) {
            NSLog(@"An error occurred when attempting to retrieve the keychain entry for %@. Error: %@", smtpUsernameString, [error localizedDescription]);
        } else {
            // Only populate the SMTP Password field if the username exists
            if (smtpUsernameString != nil && ![smtpUsernameString isEqual:@""]) {
                NSLog(@"Retrieved password from keychain for account %@.", smtpUsernameString);
                [smtpPassword setStringValue:password];
            }
        }
    }

    // Create an instance of the LGHostInfo class
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];

    if ([hostInfo gitInstalled]) {
        [installGitButton setEnabled:NO];
        [gitStatusLabel setStringValue:kGitInstalledLabel];
        [gitStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        [installGitButton setEnabled:YES];
        [gitStatusLabel setStringValue:kGitNotInstalledLabel];
        [gitStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }

    if ([hostInfo autoPkgInstalled]) {
        BOOL updateAvailable = [self autoPkgUpdateAvailable];
        if (updateAvailable) {
            [installAutoPkgButton setEnabled:YES];
            [installAutoPkgButton setTitle:@"Update AutoPkg"];
            [autoPkgStatusLabel setStringValue:kAutoPkgUpdateAvailableLabel];
            [autoPkgStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        } else {
            [installAutoPkgButton setEnabled:NO];
            [autoPkgStatusLabel setStringValue:kAutoPkgInstalledLabel];
            [autoPkgStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        }
    } else {
        [installAutoPkgButton setEnabled:YES];
        [autoPkgStatusLabel setStringValue:kAutoPkgNotInstalledLabel];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
    }

    // Enable tools buttons if directories exist
    BOOL isDir;
    NSString *autoPkgCacheFolder = [hostInfo getAutoPkgCacheDir];
    NSString *autoPkgRecipeReposFolder = [hostInfo getAutoPkgRecipeReposDir];
    NSString *localMunkiRepoFolder = [hostInfo getMunkiRepoDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgCacheFolder isDirectory:&isDir] && isDir) {
        [autoPkgCacheFolderButton setEnabled:YES];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgRecipeReposFolder isDirectory:&isDir] && isDir) {
        [autoPkgRecipeReposFolderButton setEnabled:YES];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:localMunkiRepoFolder isDirectory:&isDir] && isDir) {
        [localMunkiRepoFolderButton setEnabled:YES];
    }

    // Synchronize with the defaults database
    [defaults synchronize];
}

- (IBAction)sendTestEmail:(id)sender
{
    // Send a test email notification when the user
    // clicks "Send Test Email"

    // Handle UI
    [sendTestEmailButton setEnabled:NO]; // disable button
    [sendTestEmailStatus setHidden:YES]; // hide status light
    [sendTestEmailSpinner setHidden:NO]; // show spinner
    [sendTestEmailSpinner startAnimation:self]; // animate spinner
    [self startProgressWithMessage:@"Sending test email"];
    // First saves the defaults
    [self save];

    // Create an instance of the LGEmailer class
    LGEmailer *emailer = [[LGEmailer alloc] init];

    // Listen for notifications on completion
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(testEmailReceived:)
                                                 name:kEmailSentNotification
                                               object:emailer];

    // Send the test email notification by sending the
    // sendTestEmail message to our object
    [emailer sendTestEmail];
}

- (void)testEmailReceived:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kEmailSentNotification
                                                  object:[notification object]];

    [sendTestEmailButton setEnabled:YES]; // enable button

    // Handle Spinner
    [sendTestEmailSpinner stopAnimation:self]; // stop animation
    [sendTestEmailSpinner setHidden:YES]; // hide spinner

    // Show status light
    [sendTestEmailStatus setHidden:NO]; // unhide status light

    
    NSError *e = [[notification userInfo] objectForKey:kEmailSentNotificationError]; // pull the error out of the userInfo dictionary
    if (e) {
        [sendTestEmailStatus setImage:[NSImage imageNamed:@"NSStatusUnavailable"]]; // change status red
        NSLog(@"Error:  %@", e);
        [[NSAlert alertWithError:e] beginSheetModalForWindow:self.window
                                               modalDelegate:self
                                              didEndSelector:nil
                                                 contextInfo:nil];
    } else {
        [sendTestEmailStatus setImage:[NSImage imageNamed:@"NSStatusAvailable"]];
    }

    [self stopProgress:e];
    
}

- (void)testSmtpServerPort:(id)sender
{
    if (![[smtpServer stringValue] isEqualToString:@""] && [smtpPort integerValue
                                                            ] > 0 ) {

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // If a test is currently in progress we'll just remove the notification for it.
        [center removeObserver:self
                          name:kTestSmtpServerPortNotification
                        object:nil];

        // Set up the UI
        [testSmtpServerStatus setHidden:YES];
        [testSmtpServerSpinner setHidden:NO];
        [testSmtpServerSpinner startAnimation:self];

        LGTestPort *tester = [[LGTestPort alloc] init];

        [center addObserver:self
                   selector:@selector(testSmtpServerPortNotificationReceiver:)
                       name:kTestSmtpServerPortNotification
                     object:tester];

        [tester testHost:[NSHost hostWithName:[smtpServer stringValue]]
                withPort:[smtpPort integerValue]];

    } else {
        NSLog(@"Cannot test; either host is blank or port is unreadable.");
    }
}

- (void)testSmtpServerPortNotificationReceiver:(NSNotification *)n
{
    // Set up the spinner and show the status image
    [testSmtpServerSpinner setHidden:YES];
    [testSmtpServerSpinner stopAnimation:self];
    [testSmtpServerStatus setHidden:NO];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kTestSmtpServerPortNotification
                                                  object:[n object]];

    NSDictionary *d = [n userInfo];
    NSString *r = [d objectForKey:kTestSmtpServerPortResult];
    if ([r isEqualToString:kTestSmtpServerPortError]) {
        [testSmtpServerStatus setImage:[NSImage imageNamed:@"NSStatusUnavailable"]];
    } else if ([r isEqualToString:kTestSmtpServerPortSuccess]) {
        [testSmtpServerStatus setImage:[NSImage imageNamed:@"NSStatusAvailable"]];
    } else {
        NSLog(@"Unexpected result for kTestSmtpServerPortError.");
        [testSmtpServerStatus setImage:[NSImage imageNamed:@"NSStatusPartiallyAvailable"]];
    }
}

- (void)save
{
    [defaults setObject:[smtpServer stringValue] forKey:kSMTPServer];
    [defaults setInteger:[smtpPort integerValue] forKey:kSMTPPort];
    [defaults setObject:[smtpUsername stringValue] forKey:kSMTPUsername];
    [defaults setObject:[smtpFrom stringValue] forKey:kSMTPFrom];
    [defaults setBool:YES forKey:kHasCompletedInitialSetup];
    [defaults setObject:[localMunkiRepo stringValue] forKey:kLocalMunkiRepoPath];

    // We use objectValue here because objectValue returns an
    // array of strings if the field contains a series of strings
    [defaults setObject:[smtpTo objectValue] forKey:kSMTPTo];

    // If the value doesn’t begin with a valid decimal text
    // representation of a number integerValue will return 0.
    if ([autoPkgRunInterval integerValue] != 0) {
        [defaults setInteger:[autoPkgRunInterval integerValue] forKey:kAutoPkgRunInterval];
    }

    if ([smtpTLSEnabledButton state] == NSOnState) {
        // The user wants to enable TLS for this SMTP configuration
        NSLog(@"Enabling TLS.");
        [defaults setBool:YES forKey:kSMTPTLSEnabled];
    } else {
        // The user wants to disable TLS for this SMTP configuration
        NSLog(@"Disabling TLS.");
        [defaults setBool:NO forKey:kSMTPTLSEnabled];
    }

    if ([warnBeforeQuittingButton state] == NSOnState) {
        NSLog(@"Enabling warning before quitting.");
        [defaults setBool:YES forKey:kWarnBeforeQuittingEnabled];
    } else {
        NSLog(@"Disabling warning before quitting.");
        [defaults setBool:NO forKey:kWarnBeforeQuittingEnabled];
    }

    if ([smtpAuthenticationEnabledButton state] == NSOnState) {
        NSLog(@"Enabling SMTP authentication.");
        [defaults setBool:YES forKey:kSMTPAuthenticationEnabled];
    } else {
        NSLog(@"Disabling SMTP authentication.");
        [defaults setBool:NO forKey:kSMTPAuthenticationEnabled];
    }

    if ([sendEmailNotificationsWhenNewVersionsAreFoundButton state] == NSOnState) {
        NSLog(@"Enabling email notifications.");
        [defaults setBool:YES forKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
    } else {
        NSLog(@"Disabling email notificaitons.");
        [defaults setBool:NO forKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
    }

    if ([checkForNewVersionsOfAppsAutomaticallyButton state] == NSOnState) {
        NSLog(@"Enabling checking for new apps automatically.");
        [defaults setBool:YES forKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
    } else {
        NSLog(@"Disabling checking for new apps automatically.");
        [defaults setBool:NO forKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
    }

    if ([checkForRepoUpdatesAutomaticallyButton state] == NSOnState) {
        NSLog(@"Enabling checking for repo updates automatically.");
        [defaults setBool:YES forKey:kCheckForRepoUpdatesAutomaticallyEnabled];
    } else {
        NSLog(@"Disabling checking for repo updates automatically.");
        [defaults setBool:NO forKey:kCheckForRepoUpdatesAutomaticallyEnabled];
    }

    NSError *error;
    // Store the password used for SMTP authentication in the default keychain
    [SSKeychain setPassword:[smtpPassword stringValue] forService:kApplicationName account:[smtpUsername stringValue] error:&error];
    if (error) {
        NSLog(@"Error while storing e-mail password: %@", error);
    } else {
        NSLog(@"Reset password");
    }

    // Synchronize with the defaults database
    [defaults synchronize];

    // Start the AutoPkg run timer if the user enabled it
    [self startAutoPkgRunTimer];
}

- (BOOL)autoPkgUpdateAvailable
{
    // TODO: This check shouldn't block the main thread

    // Get the currently installed version of AutoPkg
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *installedAutoPkgVersionString = [hostInfo getAutoPkgVersion];
    NSLog(@"Installed version of AutoPkg: %@", installedAutoPkgVersionString);

    // Get the latest version of AutoPkg available on GitHub
    LGGitHubJSONLoader *jsonLoader = [[LGGitHubJSONLoader alloc] init];
    NSString *latestAutoPkgVersionString = [jsonLoader getLatestAutoPkgReleaseVersionNumber];

    // Determine if AutoPkg is up-to-date by comparing the version strings
    LGVersionComparator *vc = [[LGVersionComparator alloc] init];
    BOOL newVersionAvailable = [vc isVersion:latestAutoPkgVersionString greaterThanVersion:installedAutoPkgVersionString];
    if (newVersionAvailable) {
        NSLog(@"A new version of AutoPkg is available. Version %@ is installed and version %@ is available.", installedAutoPkgVersionString, latestAutoPkgVersionString);
        return YES;
    }

    return NO;
}

- (void)startAutoPkgRunTimer
{
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner startAutoPkgRunTimer];
}

- (void)runCommandAsRoot:(NSString *)command
{
    // Super dirty hack, but way easier than
    // using Authorization Services
    NSDictionary *error = [[NSDictionary alloc] init];
    NSString *script = [NSString stringWithFormat:@"do shell script \"sh -c '%@'\" with administrator privileges", command];
    NSLog(@"AppleScript commands: %@", script);
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    if ([appleScript executeAndReturnError:&error]) {
        NSLog(@"Authorization successful!");
    } else {
        NSLog(@"Authorization failed! Error: %@.", error);
    }
}

/*
 This should prompt for Xcode CLI tools
 installation on systems without Git.
 */
- (IBAction)installGit:(id)sender
{
    // Change the button label to "Installing..."
    // and disable the button to prevent multiple clicks
    [installGitButton setTitle:@"Installing..."];
    [installGitButton setEnabled:NO];

    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *installGitFileHandle = [pipe fileHandleForReading];
    NSString *gitCmd = @"git";

    [task setLaunchPath:gitCmd];
    [task setArguments:[NSArray arrayWithObject:@"--version"]];
    [task setStandardError:pipe];
    [task launch];
    [installGitFileHandle readInBackgroundAndNotify];
    [task waitUntilExit];

    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];

    // TODO: We should probably be installing the official
    // Git PKG rather than dealing with the Xcode CLI tools
    if ([hostInfo gitInstalled]) {
        [installGitButton setTitle:@"Install Git"];
        [installGitButton setEnabled:NO];
    }
}

- (void)downloadAndInstallAutoPkg
{
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    LGGitHubJSONLoader *jsonLoader = [[LGGitHubJSONLoader alloc] init];

    // Get the latest AutoPkg PKG download URL
    NSString *downloadURL = [jsonLoader getLatestAutoPkgDownloadURL];

    // Get path for autopkg-x.x.x.pkg
    NSString *autoPkgPkg = [NSTemporaryDirectory() stringByAppendingPathComponent:[downloadURL lastPathComponent]];

    // Download AutoPkg to the temporary directory
    NSData *autoPkg = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:downloadURL]];
    [autoPkg writeToFile:autoPkgPkg atomically:YES];

    // Set the `installer` command
    NSString *command = [NSString stringWithFormat:@"/usr/sbin/installer -pkg %@ -target /", autoPkgPkg];

    // Install the AutoPkg PKG as root
    [self runCommandAsRoot:command];

    // Update the autoPkgStatus icon and label if it installed successfully
    if ([hostInfo autoPkgInstalled]) {
        NSLog(@"AutoPkg installed successfully!");
        [autoPkgStatusLabel setStringValue:kAutoPkgInstalledLabel];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        [installAutoPkgButton setTitle:@"Install AutoPkg"];
        [installAutoPkgButton setEnabled:NO];
    }
}

- (IBAction)installAutoPkg:(id)sender
{
    // Change the button label to "Installing..."
    // and disable the button to prevent multiple clicks
    [installAutoPkgButton setTitle:@"Installing..."];
    [installAutoPkgButton setEnabled:NO];
    [self startProgressWithMessage:@"Installing newest version of AutoPkg"];

    // Download and install AutoPkg on a background thread
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
        initWithTarget:self
              selector:@selector(downloadAndInstallAutoPkg)
                object:nil];
    [queue addOperation:operation];
}

- (IBAction)openAutoPkgCacheFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *autoPkgCacheFolder = [hostInfo getAutoPkgCacheDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgCacheFolder isDirectory:&isDir] && isDir) {
        NSURL *autoPkgCacheFolderURL = [NSURL fileURLWithPath:autoPkgCacheFolder];
        [[NSWorkspace sharedWorkspace] openURL:autoPkgCacheFolderURL];
    } else {
        NSLog(@"%@ does not exist.", autoPkgCacheFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the AutoPkg Cache folder."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the AutoPkg Cache folder located in %@. Please verify that this folder exists.", kApplicationName, autoPkgCacheFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
    }
}

- (IBAction)openAutoPkgRecipeReposFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *autoPkgRecipeReposFolder = [hostInfo getAutoPkgRecipeReposDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgRecipeReposFolder isDirectory:&isDir] && isDir) {
        NSURL *autoPkgRecipeReposFolderURL = [NSURL fileURLWithPath:autoPkgRecipeReposFolder];
        [[NSWorkspace sharedWorkspace] openURL:autoPkgRecipeReposFolderURL];
    } else {
        NSLog(@"%@ does not exist.", autoPkgRecipeReposFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the AutoPkg RecipeRepos folder."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the AutoPkg RecipeRepos folder located in %@. Please verify that this folder exists.", kApplicationName, autoPkgRecipeReposFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
    }
}

- (IBAction)openLocalMunkiRepoFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *localMunkiRepoFolder = [hostInfo getMunkiRepoDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:localMunkiRepoFolder isDirectory:&isDir] && isDir) {
        NSURL *localMunkiRepoFolderURL = [NSURL fileURLWithPath:localMunkiRepoFolder];
        [[NSWorkspace sharedWorkspace] openURL:localMunkiRepoFolderURL];
    } else {
        NSLog(@"%@ does not exist.", localMunkiRepoFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the Munki Repository."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the Munki repository located in %@. Please verify that this folder exists.", kApplicationName, localMunkiRepoFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
    }
}

- (IBAction)addAutoPkgRepoURL:(id)sender
{
    // TODO: Input validation + success/failure notification

    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner addAutoPkgRecipeRepo:[repoURLToAdd stringValue]];

    [repoURLToAdd setStringValue:@""];

    [_popRepoTableViewHandler reload];
    [_appTableViewHandler reload];
}

- (IBAction)updateReposNow:(id)sender
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateReposNowCompleteNotificationRecieved:)
                                                 name:kUpdateReposCompleteNotification
                                               object:nil];

    // TODO: Success/failure notification
    [self.updateRepoNowButton setEnabled:NO];
    [self startProgressWithMessage:@"Updating autopkg repos"];

    NSLog(@"Updating AutoPkg recipe repos.");
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner invokeAutoPkgRepoUpdateInBackgroundThread];
}

- (void)updateReposNowCompleteNotificationRecieved:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kUpdateReposCompleteNotification
                                                  object:nil];
    // stop progress panel
    NSError *error = nil;
    if ([notification.object isKindOfClass:[NSError class]]) {
        error = notification.object;
    }
    [self stopProgress:error];

    // for the ui update get back on the main thread
    if ([notification.object isKindOfClass:[NSError class]]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSAlert alertWithError:notification.object] beginSheetModalForWindow:self.window
                                                                     modalDelegate:self
                                                                    didEndSelector:nil
                                                                       contextInfo:nil];
        }];
    }

    [self.updateRepoNowButton setEnabled:YES];
}

- (IBAction)checkAppsNow:(id)sender
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(autoPkgRunCompleteNotificationRecieved:)
                                                 name:kRunAutoPkgCompleteNotification
                                               object:nil];

    [self.checkAppsNowButton setEnabled:NO];
    [self startProgressWithMessage:@"Checking for new applications"];

    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner invokeAutoPkgInBackgroundThread];
}

- (void)autoPkgRunCompleteNotificationRecieved:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kRunAutoPkgCompleteNotification
                                                  object:nil];

    NSError *error = nil;
    if ([notification.object isKindOfClass:[NSError class]]) {
        error = notification.object;
    }
    [self stopProgress:error];

    [self.checkAppsNowButton setEnabled:YES];
    [self.checkAppsNowSpinner setHidden:YES];
    [self.checkAppsNowSpinner stopAnimation:nil];
}

- (IBAction)chooseLocalMunkiRepo:(id)sender
{
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    NSOpenPanel *chooseDialog = [NSOpenPanel openPanel];

    // Disable the selection of files in the dialog
    [chooseDialog setCanChooseFiles:NO];

    // Enable the selection of directories in the dialog
    [chooseDialog setCanChooseDirectories:YES];

    // Enable the creation of directories in the dialog
    [chooseDialog setCanCreateDirectories:YES];

    // Set the prompt to "Choose" instead of "Open"
    [chooseDialog setPrompt:@"Choose"];

    // Disable multiple selection
    [chooseDialog setAllowsMultipleSelection:NO];

    // Set the default directory to /Users/Shared
    [chooseDialog setDirectoryURL:[NSURL URLWithString:@"/Users/Shared"]];

    // Display the dialog. If the "Choose" button was
    // pressed, process the directory path.
    [chooseDialog beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [chooseDialog URL];
            if ([url isFileURL]) {
                BOOL isDir = NO;
                // Verify that the file exists and is a directory
                if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir] && isDir) {
                    // Here we can be certain the URL exists and it is a directory
                    NSString *urlPath = [url path];
                    [localMunkiRepo setStringValue:urlPath];
                    [autoPkgRunner setLocalMunkiRepoForAutoPkg:urlPath];
                }
            }

        }
    }];
}

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    id object = [notification object];

    if ([object isEqual:smtpServer]) {
        [defaults setObject:[smtpServer stringValue] forKey:kSMTPServer];
        [self testSmtpServerPort:self];
    } else if ([object isEqual:smtpPort]) {
        [defaults setInteger:[smtpPort integerValue] forKey:kSMTPPort];
        [self testSmtpServerPort:self];
    } else if ([object isEqual:smtpUsername]) {
        [defaults setObject:[smtpUsername stringValue] forKey:kSMTPUsername];
    } else if ([object isEqual:smtpFrom]) {
        [defaults setObject:[smtpFrom stringValue] forKey:kSMTPFrom];
    } else if ([object isEqual:localMunkiRepo]) {
        [defaults setObject:[localMunkiRepo stringValue] forKey:kLocalMunkiRepoPath];
    } else if ([object isEqual:smtpTo]) {
        // We use objectValue here because objectValue returns an
        // array of strings if the field contains a series of strings
        [defaults setObject:[smtpTo objectValue] forKey:kSMTPTo];
    } else if ([object isEqual:autoPkgRunInterval]) {
        if ([autoPkgRunInterval integerValue] != 0) {
            [defaults setInteger:[autoPkgRunInterval integerValue] forKey:kAutoPkgRunInterval];
            [self startAutoPkgRunTimer];
        }
    } else if ([object isEqual:smtpPassword]) {
        NSError *error;
        [SSKeychain setPassword:[smtpPassword stringValue] forService:kApplicationName account:[smtpUsername stringValue] error:&error];
        if (error) {
            NSLog(@"Error while storing e-mail password: %@", error);
        } else {
            NSLog(@"Reset password");
        }
    } else {
        NSLog(@"Uncaught controlTextDidEndEditing");
        return;
    }

    // Synchronize with the defaults database
    [defaults synchronize];

    // This makes the initial config screen not appear automatically on start.
    [defaults setBool:YES forKey:kHasCompletedInitialSetup];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
    // We use objectValue here because objectValue returns an
    // array of strings if the field contains a series of strings
    [defaults setObject:[smtpTo objectValue] forKey:kSMTPTo];
    [defaults synchronize];
    return tokens;
}

- (void)changeTLSButtonState
{
    if ([smtpTLSEnabledButton state] == NSOnState) {
        // The user wants to enable TLS for this SMTP configuration
        NSLog(@"Enabling TLS.");
        [defaults setBool:YES forKey:kSMTPTLSEnabled];
    } else {
        // The user wants to disable TLS for this SMTP configuration
        NSLog(@"Disabling TLS.");
        [defaults setBool:NO forKey:kSMTPTLSEnabled];
    }
    [defaults synchronize];
}


- (void)changeWarnBeforeQuittingButtonState
{
    if ([warnBeforeQuittingButton state] == NSOnState) {
        NSLog(@"Enabling warning before quitting.");
        [defaults setBool:YES forKey:kWarnBeforeQuittingEnabled];
    } else {
        NSLog(@"Disabling warning before quitting.");
        [defaults setBool:NO forKey:kWarnBeforeQuittingEnabled];
    }
    [defaults synchronize];
}

- (void)changeSmtpAuthenticationButtonState
{
    if ([smtpAuthenticationEnabledButton state] == NSOnState) {
        NSLog(@"Enabling SMTP authentication.");
        [defaults setBool:YES forKey:kSMTPAuthenticationEnabled];
    } else {
        NSLog(@"Disabling SMTP authentication.");
        [defaults setBool:NO forKey:kSMTPAuthenticationEnabled];
    }
    [defaults synchronize];
}

- (void)changeSendEmailNotificationsWhenNewVersionsAreFoundButtonState
{
    if ([sendEmailNotificationsWhenNewVersionsAreFoundButton state] == NSOnState) {
        NSLog(@"Enabling email notifications.");
        [defaults setBool:YES forKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
    } else {
        NSLog(@"Disabling email notificaitons.");
        [defaults setBool:NO forKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
    }
    [defaults synchronize];
}

- (void)changeCheckForNewVersionsOfAppsAutomaticallyButtonState
{
    if ([checkForNewVersionsOfAppsAutomaticallyButton state] == NSOnState) {
        NSLog(@"Enabling checking for new apps automatically.");
        [defaults setBool:YES forKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
    } else {
        NSLog(@"Disabling checking for new apps automatically.");
        [defaults setBool:NO forKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
    }
    [defaults synchronize];
    [self startAutoPkgRunTimer];
}

- (void)changeCheckForRepoUpdatesAutomaticallyButtonState
{
    if ([checkForRepoUpdatesAutomaticallyButton state] == NSOnState) {
        NSLog(@"Enabling checking for repo updates automatically.");
        [defaults setBool:YES forKey:kCheckForRepoUpdatesAutomaticallyEnabled];
    } else {
        NSLog(@"Disabling checking for repo updates automatically.");
        [defaults setBool:NO forKey:kCheckForRepoUpdatesAutomaticallyEnabled];
    }
    [defaults synchronize];
}

- (void)updateProgressNotificationReceived:(NSNotification *)notification
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if ([notification.object isKindOfClass:[NSString class]]) {
            self.progressMessage.stringValue = notification.object;
        }
    }];
}
- (void)startProgressNotificationReceived:(NSNotification *)notification
{
    [self startProgressWithMessage:notification.object];
}

- (void)stopProgressNotificationReceived:(NSNotification *)notification
{
    NSError *error = nil;
    if ([notification.object isKindOfClass:[NSError class]]) {
        error = notification.object;
    }
    [self stopProgress:error];
}

- (void)startProgressWithMessage:(NSString *)message
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressMessage setStringValue:message];
        [NSApp beginSheet:self.progressPanel modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:NULL];
        [self.progressIndicator setHidden:NO];
        [self.progressIndicator setIndeterminate:YES];
        [self.progressIndicator displayIfNeeded];
        [self.progressIndicator startAnimation:nil];

    }];
}

- (void)stopProgress:(NSError *)error
{
    // Stop the progress panel, and if and error was sent in
    // do a sheet modal
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.progressPanel orderOut:self];
        [NSApp endSheet:self.progressPanel returnCode:0];
        [self.progressMessage setStringValue:@"Starting..."];
        if (error) {
            [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window
                                                       modalDelegate:self
                                                      didEndSelector:nil
                                                         contextInfo:nil];
        }
    }];
}


- (BOOL)windowShouldClose:(id)sender
{
    [self save];

    return YES;
}

@end
