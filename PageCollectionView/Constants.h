//
//  Constants.h
//  PageCollectionView
//
//  Created by Adam Wulf on 10/28/19.
//  Copyright © 2019 Milestone Made. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define MMBoundingSizeFor(itemSize, rotation) _MMBoundingSizeFor(itemSize, rotation)
#define MMFitSizeToWidth(itemSize, targetWidth, scaleUpToFit) _MMFitSizeToWidth(itemSize, targetWidth, scaleUpToFit)
#define MMFitSizeToHeight(itemSize, targetHeight, scaleUpToFit) _MMFitSizeToHeight(itemSize, targetHeight, scaleUpToFit)
#define CGSizeForInscribedWidth(ratio, width, rotation) _CGSizeForInscribedWidth(ratio, width, rotation)
#define CGSizeForInscribedHeight(ratio, height, rotation) _CGSizeForInscribedHeight(ratio, height, rotation)

/// @param itemSize the size of the box to rotate
/// @param rotation the angle of the box to rotate
/// @returns the size of the box needed to inscribe the rotated box
/// Return the size of the box needed to full inscribe the rotated box defined by the input size
static inline CGSize _MMBoundingSizeFor(CGSize itemSize, CGFloat rotation)
{
    CGRect bounds = CGRectMake(0, 0, itemSize.width, itemSize.height);
    CGRect rotatedBounds = CGRectApplyAffineTransform(bounds, CGAffineTransformMakeRotation(rotation));
    return rotatedBounds.size;
}

/// Scale the input size so that its width is the input targetWidth, and its height is scaled proportionally
static inline CGSize _MMFitSizeToWidth(CGSize itemSize, CGFloat targetWidth, BOOL scaleUp)
{
    if (scaleUp || itemSize.width > targetWidth) {
        return CGSizeMake(targetWidth, targetWidth / itemSize.width * itemSize.height);
    } else {
        return itemSize;
    }
}

static inline CGSize _MMFitSizeToHeight(CGSize itemSize, CGFloat targetHeight, BOOL scaleUp)
{
    if (scaleUp || itemSize.height > targetHeight) {
        return CGSizeMake(targetHeight * itemSize.width / itemSize.height, targetHeight);
    } else {
        return itemSize;
    }
}

/**
 * Calculate the size of a box that will inscribe a containing box of input width. The incribed box
 * @param ratio the ratio of height / width for the box that will be inscribed
 * @param rotation the angle that the incribed box is rotated
 * @param fitWidth the width of the box that contains the inscribed box
 *
 * to do that, if W is the scaled width of the page, H is the
 * scaled height of of the page, and FW is the fitWidth, and
 * A is the angle that the page has been rotated, then:
 *
 * FW == cos(A) * W + sin(A) * H
 * and we know that H / W == R, so
 * FW == cos(A) * W + sin(A) * W * R
 * FW == (cos(A) + sin(A) * R) * W
 * W == SW / (cos(A) + sin(A) * R)
 * H = W * R
 *
 * care needs to be taken to use the ABS() of the sine and cosine
 * otherwise the sum of the two will cancel out and leave us with
 * the wrong ratio. Signs of these probably matter to tell us left/right
 * or some other thing we can ignore.
 */
static inline CGSize _CGSizeForInscribedWidth(CGFloat ratio, CGFloat fitWidth, CGFloat rotation)
{
    CGFloat newWidth = fitWidth / (ABS(sin(rotation) * ratio) + ABS(cos(rotation)));
    return CGSizeMake(ABS(newWidth), ABS(newWidth * ratio));
}

/**
 * FH == cos(A) * H + sin(A) * W
 * and we know that H / W == R, so
 * FH == cos(A) * H + sin(A) * H / R
 * FH == (cos(A) + sin(A) / R) * H
 * H == FH / (cos(A) + sin(A) / R)
 * H = W * R
 */
static inline CGSize _CGSizeForInscribedHeight(CGFloat ratio, CGFloat fitHeight, CGFloat rotation)
{
    CGFloat newHeight = fitHeight / (ABS(cos(rotation)) + ABS(sin(rotation) / ratio));
    return CGSizeMake(ABS(newHeight / ratio), ABS(newHeight));
}


#endif /* Constants_h */
