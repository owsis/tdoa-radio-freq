
#include "math.h"
#include "double.h"
#include "filters.h"

void lowPass( ld_t * T, double stop_freq, ld_t * W, int aLen ) {
    int M = ( aLen - 1 ) / 2 ;
    ld_t fwT0 = 2.0L * M_PI * stop_freq ;

    for ( int n = -M ; n <= M ; n++ )
        if ( n == 0 )
            T[ n + M ] = fwT0 / M_PI * W[ n + M ] ;
        else
            T[ n + M ] = sin( n * fwT0 ) / ( n * M_PI ) * W[ n + M ] ;

    ld_t scale = 2.0L * fabsl( T[ 0 + M ] ) ;
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void highPass( ld_t * T, double start_freq, ld_t * W, int aLen ) {
    int M = ( aLen - 1 ) / 2 ;
    ld_t fwT0 = 2.0L * M_PI * start_freq ;

    for ( int n = -M; n <= M; n++ )
        if ( n == 0 )
            T[ n + M ] = ( 1 - ( fwT0 / M_PI ) ) * W[ n + M ] ;
        else
            T[ n + M ] = -sin( n * fwT0 ) / ( n * M_PI ) * W[ n + M ] ;

    ld_t scale = 2.0L * fabsl( T[ 0 + M ] ) ;
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void bandPass( ld_t * T, double start_freq, double stop_freq, ld_t * W, int aLen ) {
    int M = ( aLen - 1 ) / 2 ;
    ld_t fwT0 = 2.0L * M_PI * start_freq ;
    ld_t fwT1 = 2.0L * M_PI * stop_freq ;

    for ( int n = -M; n <= M; n++ )
        if ( n == 0 )
            T[ n + M ] = ( fwT1 - fwT0 ) * W[ n + M ] / M_PI ;
        else
            T[ n + M ] = ( sin( n * fwT1 ) - sin( n * fwT0 ) ) * W[ n + M ] / ( n * M_PI ) ;

    ld_t scale = 2.0L * fabsl( T[ 0 + M ] ) ;
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void bandStop( ld_t * T, double stop_freq, double start_freq, ld_t * W, int aLen ) {
    int M = ( aLen - 1 ) / 2 ;
    ld_t fwT0 = 2.0L * M_PI * stop_freq ;
    ld_t fwT1 = 2.0L * M_PI * start_freq ;

    for ( int n = -M ; n <= M ; n++ )
        if ( n == 0 )
            T[ n + M ] = 1.0L - ( fwT1 - fwT0 ) * W[ n + M ] / M_PI ;
        else
            T[ n + M ] = ( sin( n * fwT0 ) - sin( n * fwT1 ) ) * W[ n + M ] / ( n * M_PI ) ;

    ld_t scale = 2.0L * fabsl( T[ 0 + M ] ) ;
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void differentiator( ld_t * T, double stop_freq, double start_freq, ld_t * W, int aLen ) {
    int M = ( aLen - 1 ) / 2 ;
    ld_t fwT0 = 2.0L * M_PI * stop_freq ;
    ld_t fwT1 = 2.0L * M_PI * start_freq ;

    for ( int n = -M ; n <= M ; n++ )
        if ( n == 0 )
            T[ n + M ] = 1.0L - ( fwT1 - fwT0 ) * W[ n + M ] / M_PI ;
        else
            T[ n + M ] = ( sin( n * fwT0 ) - sin( n * fwT1 ) ) * W[ n + M ] / ( n * M_PI ) ;

    ld_t scale = 2.0L * fabsl( T[ 0 + M ] ) ;
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void gaussian( ld_t * T, double spb, double bt, int aLen ) {
    ld_t dt = 1.0L / spb ;
    ld_t s = 1.0 / ( sqrtl( logl( 2.0L ) ) / ( 2.0L * (ld_t)M_PI * bt ) ) ;

    ld_t t0 = -0.5L * aLen - 0.5L ;
    ld_t scale = 0.0L ;

    for ( int i = 0 ; i < aLen ; i++ ) {
        t0 += 1.0L ;
        ld_t ts = s * dt * t0 ;
        T[ i ] = expl( -0.5L * ts * ts ) ;
        scale += T[ i ] ;
    }
    for ( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}

void rootRaisedCosine( ld_t * T, double spb, double alpha, int aLen ) {
    double scale = 0 ;

    for ( int i = 0 ; i < aLen ; i++ ) {
        double x1, x2, x3, num, den ;
        double xindx = i - aLen / 2 ;
        x1 = M_PI * xindx / spb ;
        x2 = 4 * alpha * xindx / spb ;
        x3 = x2 * x2 - 1 ;

        if ( fabs( x3 ) >= 0.000001 ) {  // Avoid Rounding errors...
            if ( i != aLen / 2 )
                num = cos( ( 1.0 + alpha ) * x1 ) + sin( ( 1.0 - alpha ) * x1 ) / ( 4 * alpha * xindx / spb ) ;
            else
                num = cos( ( 1.0 + alpha ) * x1 ) + ( 1.0 - alpha ) * M_PI / ( 4 * alpha ) ;
            den = x3 * M_PI ;
        } else {
            if ( alpha == 1 ) {
                T[ i ] = -1 ;
                continue ;
            }
            x3 = ( 1 - alpha ) * x1 ;
            x2 = ( 1 + alpha ) * x1 ;
            num = ( sin( x2 ) * ( 1.0 + alpha ) * M_PI
                - cos( x3 ) * ( ( 1.0 - alpha ) * M_PI * spb ) / ( 4 * alpha * xindx )
                + sin( x3 ) * spb * spb / ( 4 * alpha * xindx * xindx ) ) ;
            den = -32 * M_PI * alpha * alpha * xindx / spb ;
        }
        T[i] = 4 * alpha * num / den ;
        scale += T[ i ] ;
    }
    for( int i = 0 ; i < aLen ; i++ )
        T[ i ] /= scale ;
}


