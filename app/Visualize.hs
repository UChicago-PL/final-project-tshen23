module Visualize where

import Data.Time ( Day )
import Graphics.Rendering.Chart.Easy
import Graphics.Rendering.Chart.Backend.Diagrams ( toFile )

-- convert daily returns to cumulative growth
cumulativeSeries :: [(Day, Double)] -> [(Day, Double)]
cumulativeSeries [] = []
cumulativeSeries dated =
    let go _ [] = []
        go acc ((d, r):rest) =
            let acc' = acc * (1 + r)
            in (d, acc') : go acc' rest
    in go 1.0 dated

-- render a PNG comparing multiple index series
renderChart :: FilePath -> [(String, [(Day, Double)])] -> IO ()
renderChart outPath series = toFile def outPath $ do
    layout_title .= "Index Performance Comparison"
    layout_x_axis . laxis_title .= "Date"
    layout_y_axis . laxis_title .= "Growth of $1"
    mapM_ addSeries series where
    addSeries (seriesLabel, dated) = do
        let cumulative = cumulativeSeries dated
        plot (line seriesLabel [cumulative])