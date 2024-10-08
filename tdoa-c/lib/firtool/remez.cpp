/**************************************************************************
 * Parks-McClellan algorithm for FIR filter design (C version)
 *-------------------------------------------------
 *  Copyright (c) 1995,1998  Jake Janovetz (janovetz@uiuc.edu)
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public
 *  License along with this library; if not, write to the Free
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *
 *  Sep 1999 - Paul Kienzle (pkienzle@cs.indiana.edu)
 *      Modified for use in octave as a replacement for the matlab function
 *      remez.mex.  In particular, magnitude responses are required for all
 *      band edges rather than one per band, griddensity is a parameter,
 *      and errors are returned rather than printed directly.
 *  Mar 2000 - Kai Habel (kahacjde@linux.zrz.tu-berlin.de)
 *      Change: ColumnVector x=arg(i).vector_value();
 *      to: ColumnVector x(arg(i).vector_value());
 *  There appear to be some problems with the routine Search. See comments
 *  therein [search for PAK:].  I haven't looked closely at the rest
 *  of the code---it may also have some problems.
 *************************************************************************/

#include <math.h>
#include "double.h"
#include "remez.h"

typedef enum _PN {
    NEGATIVE = 0,
    POSITIVE = 1
} PN_t ;

const int GRIDDENSITY = 16 ;
const int MAXITERATIONS = 40 ;

/*******************
 * CreateDenseGrid
 *=================
 * Creates the dense grid of frequencies from the specified bands.
 * Also creates the Desired Frequency Response function (D[]) and
 * the Weight function (W[]) on that dense grid
 *
 *
 * INPUT:
 * ------
 * int      r        - 1/2 the number of filter coefficients
 * int      numtaps  - Number of taps in the resulting filter
 * int      numband  - Number of bands in user specification
 * double   bands[]  - User-specified band edges [2*numband]
 * double   des[]    - Desired response per band [2*numband]
 * double   weight[] - Weight per band [numband]
 * int      symmetry - Symmetry of filter - used for grid check
 * int      griddensity
 *
 * OUTPUT:
 * -------
 * int    gridsize   - Number of elements in the dense frequency grid
 * double Grid[]     - Frequencies (0 to 0.5) on the dense grid [gridsize]
 * double D[]        - Desired response on the dense grid [gridsize]
 * double W[]        - Weight function on the dense grid [gridsize]
 *******************/

static void CreateDenseGrid(
    int r, int numtaps, int numband, const ld_t bands[],
    const ld_t des[], const ld_t weight[], int gridsize,
    ld_t Grid[], ld_t D[], ld_t W[],
    int symmetry, int griddensity
) {
   ld_t delf = 0.5L / ( griddensity * r ) ;

/*
 * For differentiator, hilbert,
 *   symmetry is odd and Grid[0] = max(delf, bands[0])
 */
   ld_t grid0 = ( symmetry == NEGATIVE ) && ( delf > bands[ 0 ] ) ? delf : bands[ 0 ] ;

   int j = 0 ;
   for ( int band=0; band < numband; band++ ) {
      ld_t lowf = ( band == 0 ? grid0 : bands[ 2 * band ] ) ;
      ld_t highf = bands[ 2 * band + 1 ] ;
      int k = (int)((highf - lowf)/delf + 0.5);   /* .5 for rounding */
      for ( int i = 0 ; i < k ; i++ ) {
         D[ j ] = des[ 2 * band ] + i * ( des[ 2 * band + 1 ] - des[ 2 * band ] ) / ( k - 1 ) ;
         W[ j ] = weight[ band ] ;
         Grid[ j ] = lowf ;
         lowf += delf ;
         j++ ;
      }
      Grid[ j - 1 ] = highf ;
   }

/*
 * Similar to above, if odd symmetry, last grid point can't be .5
 *  - but, if there are even taps, leave the last grid point at .5
 */
    if (
        ( symmetry == NEGATIVE ) &&
        ( Grid[gridsize-1] > (0.5 - delf) ) &&
        ( numtaps % 2 )
    )
        Grid[ gridsize - 1 ] = 0.5 - delf ;
}


/********************
 * InitialGuess
 *==============
 * Places Extremal Frequencies evenly throughout the dense grid.
 *
 *
 * INPUT: 
 * ------
 * int r        - 1/2 the number of filter coefficients
 * int gridsize - Number of elements in the dense frequency grid
 *
 * OUTPUT:
 * -------
 * int Ext[]    - Extremal indexes to dense frequency grid [r+1]
 ********************/

static void InitialGuess( int r, int Ext[], int gridsize ) {
   for ( int i = 0 ; i <= r ; i++ )
      Ext[i] = i * (gridsize-1) / r ;
}


/***********************
 * CalcParms
 *===========
 *
 *
 * INPUT:
 * ------
 * int    r      - 1/2 the number of filter coefficients
 * int    Ext[]  - Extremal indexes to dense frequency grid [r+1]
 * double Grid[] - Frequencies (0 to 0.5) on the dense grid [gridsize]
 * double D[]    - Desired response on the dense grid [gridsize]
 * double W[]    - Weight function on the dense grid [gridsize]
 *
 * OUTPUT:
 * -------
 * double ad[]   - 'b' in Oppenheim & Schafer [r+1]
 * double x[]    - [r+1]
 * double y[]    - 'C' in Oppenheim & Schafer [r+1]
 ***********************/

static void CalcParms(
    int r, int Ext[], ld_t Grid[], ld_t D[], ld_t W[],
    ld_t ad[], ld_t x[], ld_t y[]
) {
/*
 * Find x[]
 */
   for ( int i = 0 ; i <=r ; i++ )
      x[ i ] = cos( M_PI * 2.0 * Grid[Ext[i]] ) ;

/*
 * Calculate ad[]  - Oppenheim & Schafer eq 7.132
 */
   int ld = ( r - 1 ) / 15 + 1 ;         /* Skips around to avoid round errors */
   for ( int i = 0 ; i <= r ; i++ ) {
       double denom = 1.0 ;
       double xi = x[ i ] ;
       for ( int j = 0 ; j < ld ; j++ ) {
          for ( int k = j ; k <= r ; k += ld )
             if ( k != i )
                denom *= 2.0*( xi - x[ k ] ) ;
       }
       if ( fabs( denom ) < 1e-12 )
          denom = 1e-12 ;
       ad[ i ] = 1.0 / denom ;
   }

/*
 * Calculate delta  - Oppenheim & Schafer eq 7.131
 */
   double denom = 0.0 ;
   double numer = 0.0 ;
   double sign = 1 ;
   for ( int i = 0 ; i <= r ; i++ ) {
      numer += ad[ i ] * D[ Ext[ i ] ] ;
      denom += sign * ad[ i ] / W[ Ext[ i ] ] ;
      sign = -sign ;
   }
   double delta = numer / denom ;
   sign = 1 ;

/*
 * Calculate y[]  - Oppenheim & Schafer eq 7.133b
 */
   for ( int i = 0 ; i <= r ; i++ ) {
      y[i] = D[ Ext[ i ] ] - sign * delta / W[ Ext[ i ] ] ;
      sign = -sign ;
   }
}


/*********************
 * ComputeA
 *==========
 * Using values calculated in CalcParms, ComputeA calculates the
 * actual filter response at a given frequency (freq).  Uses
 * eq 7.133a from Oppenheim & Schafer.
 *
 *
 * INPUT:
 * ------
 * double freq - Frequency (0 to 0.5) at which to calculate A
 * int    r    - 1/2 the number of filter coefficients
 * double ad[] - 'b' in Oppenheim & Schafer [r+1]
 * double x[]  - [r+1]
 * double y[]  - 'C' in Oppenheim & Schafer [r+1]
 *
 * OUTPUT:
 * -------
 * Returns double value of A[freq]
 *********************/

static double ComputeA(ld_t freq, int r, ld_t ad[], ld_t x[], ld_t y[]) {
   double denom = 0.0 ;
   double numer = 0.0 ;
   double xc = cos( M_PI * 2.0 * freq ) ;
   for ( int i = 0 ; i <= r ; i++ ) {
      double c = xc - x[ i ] ;
      if ( fabs(c) < 1.0e-7 ) {
         numer = y[ i ] ;
         denom = 1 ;
         break;
      }
      c = ad[i] / c ;
      denom += c ;
      numer += c * y[ i ] ;
   }
   return numer / denom ;
}


/************************
 * CalcError
 *===========
 * Calculates the Error function from the desired frequency response
 * on the dense grid (D[]), the weight function on the dense grid (W[]),
 * and the present response calculation (A[])
 *
 *
 * INPUT:
 * ------
 * int    r      - 1/2 the number of filter coefficients
 * double ad[]   - [r+1]
 * double x[]    - [r+1]
 * double y[]    - [r+1]
 * int gridsize  - Number of elements in the dense frequency grid
 * double Grid[] - Frequencies on the dense grid [gridsize]
 * double D[]    - Desired response on the dense grid [gridsize]
 * double W[]    - Weight function on the desnse grid [gridsize]
 *
 * OUTPUT:
 * -------
 * double E[]    - Error function on dense grid [gridsize]
 ************************/

static void CalcError(int r, ld_t ad[], ld_t x[], ld_t y[],
               int gridsize, ld_t Grid[],
               ld_t D[], ld_t W[], ld_t E[]) {
   for ( int i = 0 ; i < gridsize ; i++ ) {
      ld_t A = ComputeA( Grid[ i ], r, ad, x, y);
      E[ i ] = W[ i ] * ( D[ i ] - A );
   }
}

/************************
 * Search
 *========
 * Searches for the maxima/minima of the error curve.  If more than
 * r+1 extrema are found, it uses the following heuristic (thanks
 * Chris Hanson):
 * 1) Adjacent non-alternating extrema deleted first.
 * 2) If there are more than one excess extrema, delete the
 *    one with the smallest error.  This will create a non-alternation
 *    condition that is fixed by 1).
 * 3) If there is exactly one excess extremum, delete the smaller
 *    of the first/last extremum
 *
 *
 * INPUT:
 * ------
 * int    r        - 1/2 the number of filter coefficients
 * int    Ext[]    - Indexes to Grid[] of extremal frequencies [r+1]
 * int    gridsize - Number of elements in the dense frequency grid
 * double E[]      - Array of error values.  [gridsize]
 * OUTPUT:
 * -------
 * int    Ext[]    - New indexes to extremal frequencies [r+1]
 ************************/
static int Search( int r, int Ext[], int gridsize, ld_t E[] ) {
/*
 * Allocate enough space for found extremals.
 */
   int foundExt[ 2 * r ] ;
   int k = 0 ;

/*
 * Check for extremum at 0.
 */
   if ( ( ( E[0]>0.0 ) && ( E[0]>E[1] ) ) || ( ( E[0]<0.0 ) && ( E[0]<E[1] ) ) )
      foundExt[ k++ ] = 0 ;

/*
 * Check for extrema inside dense grid
 */
   for ( int i = 1; i < gridsize - 1 ; i++ ) {
      if (((E[i]>=E[i-1]) && (E[i]>E[i+1]) && (E[i]>0.0)) ||
          ((E[i]<=E[i-1]) && (E[i]<E[i+1]) && (E[i]<0.0))) {
	// PAK: we sometimes get too many extremal frequencies
    if ( k >= 2 * r )
        return -3 ;
    foundExt[ k++ ] = i ;
      }
   }

/*
 * Check for extremum at 0.5
 */
   int j = gridsize-1;
   if (((E[j]>0.0) && (E[j]>E[j-1])) || ((E[j]<0.0) && (E[j]<E[j-1]))) {
     if ( k >= 2 * r )
         return -3 ;
     foundExt[k++] = j ;
   }

   // PAK: we sometimes get not enough extremal frequencies
   if ( k < r + 1 )
       return -2 ;

/*
 * Remove extra extremals
 */
   int extra = k - (r + 1 );
//   assert(extra >= 0) ;

   while ( extra > 0 ) {
      int up = 0 ;

      if ( E[foundExt[0]] > 0.0 )
         up = 1;                /* first one is a maxima */
      else
         up = 0;                /* first one is a minima */

      int l = 0 ;
      int alt = 1;
      for (int j = 1; j < k ; j++ ) {
         if ( fabs(E[foundExt[j]]) < fabs(E[foundExt[l]]) )
            l = j ;               /* new smallest error. */
         if ((up) && (E[foundExt[j]] < 0.0))
            up = 0 ;             /* switch to a minima */
         else if ((!up) && (E[foundExt[j]] > 0.0))
            up = 1 ;             /* switch to a maxima */
         else {
            alt = 0;
            // PAK: break now and you will delete the smallest overall
            // extremal.  If you want to delete the smallest of the
            // pair of non-alternating extremals, then you must do:
                //
            // if (fabs(E[foundExt[j]]) < fabs(E[foundExt[j-1]])) l=j;
            // else l=j-1;
            break;              /* Ooops, found two non-alternating */
         }                      /* extrema.  Delete smallest of them */
      }  /* if the loop finishes, all extrema are alternating */

/*
 * If there's only one extremal and all are alternating,
 * delete the smallest of the first/last extremals.
 */
      if ((alt) && ( extra == 1 ) ) {
         if ( fabs( E[foundExt[k-1]]) < fabs(E[foundExt[0]] ) )
           /* Delete last extremal */
           l = k-1;
           // PAK: changed from l = foundExt[k-1];
         else
           /* Delete first extremal */
           l = 0;
           // PAK: changed from l = foundExt[0];
      }

      for ( int j=l; j<k-1; j++ ) {        /* Loop that does the deletion */
         foundExt[j] = foundExt[j+1];
//	 assert(foundExt[j]<gridsize);
      }
      k-- ;
      extra-- ;
   }

   for ( int i=0; i<=r; i++ ) {
//      assert(foundExt[i]<gridsize);
      Ext[ i ] = foundExt[ i ] ;       /* Copy found extremals to Ext[] */
   }
   return 0 ;
}


/*********************
 * FreqSample
 *============
 * Simple frequency sampling algorithm to determine the impulse
 * response h[] from A's found in ComputeA
 *
 *
 * INPUT:
 * ------
 * int      N        - Number of filter coefficients
 * double   A[]      - Sample points of desired response [N/2]
 * int      symmetry - Symmetry of desired filter
 *
 * OUTPUT:
 * -------
 * double h[] - Impulse Response of final filter [N]
 *********************/
static void FreqSample( int N, ld_t A[], ld_t h[], int symm ) {
   double M = ( N - 1.0 ) / 2.0 ;
   if ( symm == POSITIVE ) {
      if ( N%2 ) {
         for ( int n = 0 ; n < N ; n++ ) {
            ld_t val = A[ 0 ] ;
            double x = M_PI * 2.0 * ( n - M ) / N ;
            for ( int k = 1 ; k <= M ; k++ )
               val += 2.0 * A[ k ] * cos( x * k ) ;
            h[n] = val/N;
         }
      } else {
         for ( int n = 0 ; n < N ; n++ ) {
            ld_t val = A[ 0 ] ;
            double x = M_PI * 2.0 * ( n - M ) / N ;
            for ( int k = 1 ; k<=( N / 2 - 1 ) ; k++ )
               val += 2.0 * A[ k ] * cos( x * k ) ;
            h[n] = val/N;
         }
      }
   } else {
      if (N%2) {
         for ( int n = 0 ; n < N ; n++ ) {
            ld_t val = 0 ;
            double x = M_PI * 2.0 * ( n - M ) / N ;
            for ( int k = 1 ; k <= M ; k++ )
               val += 2.0 * A[ k ] * sin( x * k ) ;
            h[n] = val / N ;
         }
      } else {
          for ( int n = 0 ; n < N ; n++ ) {
             ld_t val = A[ N / 2 ] * sin( M_PI * ( n - M ) ) ;
             double x = M_PI * 2.0 * ( n - M ) / N ;
             for ( int k = 1 ; k <= ( N / 2 - 1 ) ; k++ )
                val += 2.0 * A[ k ] * sin( x * k ) ;
             h[n] = val / N ;
          }
      }
   }

   ld_t max = 0.0L ;
   for ( int n = 0 ; n < N ; n++ )
       if ( max < fabs( h[ n ] ) )
            max = fabs( h[ n ] ) ;
   for ( int n = 0 ; max > 0.0L && n < N ; n++ )
       h[ n ] /= max * 2.0L ;
}

/*******************
 * isDone
 *========
 * Checks to see if the error function is small enough to consider
 * the result to have converged.
 *
 * INPUT:
 * ------
 * int    r     - 1/2 the number of filter coeffiecients
 * int    Ext[] - Indexes to extremal frequencies [r+1]
 * double E[]   - Error function on the dense grid [gridsize]
 *
 * OUTPUT:
 * -------
 * Returns 1 if the result converged
 * Returns 0 if the result has not converged
 ********************/

static int isDone( int r, int Ext[], ld_t E[] ) {
   double min, max ;

   min = max = fabs( E[ Ext[0] ] ) ;
   for (int i = 1 ; i <= r ; i++ ) {
      double current = fabs( E[ Ext[ i ] ] ) ;
      if ( current < min )
         min = current ;
      if ( current > max)
         max = current ;
   }
   return ( ( ( max - min ) / max ) < 1e-12 ) ;
}

/********************
 * remez
 *=======
 * Calculates the optimal (in the Chebyshev/minimax sense)
 * FIR filter impulse response given a set of band edges,
 * the desired reponse on those bands, and the weight given to
 * the error in those bands.
 *
 * INPUT:
 * ------
 * int     numtaps     - Number of filter coefficients
 * int     numband     - Number of bands in filter specification
 * double  bands[]     - User-specified band edges [2 * numband]
 * double  des[]       - User-specified band responses [2 * numband]
 * double  weight[]    - User-specified error weights [numband]
 * int     type        - Type of filter
 *
 * OUTPUT:
 * -------
 * double h[]      - Impulse response of final filter [numtaps]
 * returns         - true on success, false on failure to converge
 ********************/

int remez( ld_t h[], int numtaps, int numband, const ld_t bands[],
      const ld_t des[], const ld_t weight[], REMEZ_t type, int griddensity
) {
   int symmetry = POSITIVE ;

   if ( type == BANDPASS )
      symmetry = POSITIVE ;
   else
      symmetry = NEGATIVE ;

   int r = numtaps / 2 ;                  /* number of extrema */
   if ( ( numtaps % 2 ) && ( symmetry == POSITIVE ) )
      r++ ;

/*
 * Predict dense grid size in advance for memory allocation
 *   .5 is so we round up, not truncate
 */
   int gridsize = 0 ;
   for ( int i = 0 ; i < numband ; i++ )
      gridsize += (int)( 2.0 * r * griddensity * ( bands[ 2 * i + 1 ] - bands[ 2 * i ] ) + 0.5 ) ;
   if ( symmetry == NEGATIVE )
      gridsize-- ;

/*
 * Dynamically allocate memory for arrays with proper sizes
 */
   ld_t * Grid = new ld_t[ gridsize ] ;
   ld_t * D = new ld_t[ gridsize ] ;
   ld_t * W = new ld_t[ gridsize ] ;
   ld_t * E = new ld_t[ gridsize ] ;

   int Ext[ r + 1 ] ;
   ld_t taps[ r + 1 ] ;
   ld_t x[ r + 1 ] ;
   ld_t y[ r + 1 ] ;
   ld_t ad[ r + 1 ] ;

/*
 * Create dense frequency grid
 */
   CreateDenseGrid( r, numtaps, numband, bands, des, weight, gridsize, Grid, D, W, symmetry, griddensity ) ;
   InitialGuess( r, Ext, gridsize ) ;

/*
 * For Differentiator: (fix grid)
 */
   if ( type == DIFFERENTIATOR ) {
      for ( int i = 0 ; i < gridsize ; i++ ) {
/* D[i] = D[i]*Grid[i]; */
         if ( D[i] > 1e-12 )
            W[i] = W[i] / Grid[i] ;
      }
   }

/*
 * For odd or Negative symmetry filters, alter the
 * D[] and W[] according to Parks McClellan
 */
   ld_t c ;
   int iter ;

   if ( symmetry == POSITIVE ) {
      if ( numtaps % 2 == 0 ) {
         for ( int i = 0 ; i < gridsize ; i++ ) {
            c = cos( M_PI * Grid[i] ) ;
            D[ i ] /= c ;
            W[ i ] *= c ;
         }
      }
   } else {
      if ( numtaps % 2 ) {
         for ( int i = 0 ; i < gridsize ; i++ ) {
            c = sin( M_PI * 2.0 * Grid[i] ) ;
            D[ i ] /= c ;
            W[ i ] *= c ;
         }
      } else {
         for ( int i = 0 ; i < gridsize ; i++ ) {
            c = sin( M_PI * Grid[i] ) ;
            D[ i ] /= c ;
            W[ i ] *= c ;
         }
      }
   }

/*
 * Perform the Remez Exchange algorithm
 */
   int err = 0 ;

   for ( iter = 0 ; iter < MAXITERATIONS ; iter++ ) {
      CalcParms( r, Ext, Grid, D, W, ad, x, y ) ;
      CalcError( r, ad, x, y, gridsize, Grid, D, W, E ) ;
      err = Search( r, Ext, gridsize, E ) ;
      if ( err != 0 )
          goto err_ret ;
//      for( int i=0; i <= r; i++)
//          assert(Ext[i]<gridsize);
      if ( isDone( r, Ext, E ) )
         break ;
   }

   CalcParms( r, Ext, Grid, D, W, ad, x, y ) ;

/*
 * Find the 'taps' of the filter for use with Frequency
 * Sampling.  If odd or Negative symmetry, fix the taps
 * according to Parks McClellan
 */
   for ( int i = 0 ; i <= numtaps / 2 ; i++ ) {
      if ( symmetry == POSITIVE ) {
         if ( numtaps % 2 )
            c = 1.0L ;
         else
            c = cos( M_PI * (double)i / numtaps ) ;
      } else {
         if ( numtaps % 2 )
            c = sin( M_PI * 2.0 * (double)i / numtaps ) ;
         else
            c = sin( M_PI * (double)i / numtaps ) ;
      }
      taps[ i ] = ComputeA( (double)i / numtaps, r, ad, x, y ) * c ;
   }

/*
 * Frequency sampling design with calculated taps
 */
   FreqSample( numtaps, taps, h, symmetry ) ;

   err = iter < MAXITERATIONS ? 0 : -1 ;

err_ret:
   delete Grid ;
   delete D ;
   delete W ;
   delete E ;

   return err ;
}

