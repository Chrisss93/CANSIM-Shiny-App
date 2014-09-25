library(shiny)

shinyUI(fluidPage(
  shinyIncubator::progressInit(),
  titlePanel("CANSIM 202-0802 Interactive Visualization"),
  h5("Christopher Lee"),
  sidebarLayout(
    sidebarPanel(
      checkboxGroupInput("line", "Select Poverty line:" , 
                  choices = c("LICO" = "Low income cut-offs after tax, 1992 base",
                              "LIM"  = "Low income measure after tax", 
                              "MBM"  = "Market basket measure, 2011 base"),
                  selected = "Low income cut-offs after tax, 1992 base"), 
      selectInput("pop", "Select a gender parameter:" ,
                  choices = c("All", "Male", "Female")) ,
      selectInput("pop2", "Select an age parameter:" ,
                  choices = c("All", "Children", "Adults", "Elderly")) ,
      selectInput("geo", "Select a geography parameter:" ,
                  choices = c("Canada", "Atlantic provinces", "Prairie provinces",
                              "Ontario", "Quebec", "British Columbia", "Alberta",
                              "Saskatchewan", "Manitoba", "Newfoundland and Labrador",
                              "Nova Scotia", "New Brunswick", "Prince Edward Island")),
      downloadButton("downloadRaw", "Download data"),
      helpText("* Note: For simplicity, the Population parameter only captures age and gender categories.
               For similar reasons, the Geography parameter only captures provincial identifiers.")
    ), 

    mainPanel(
      tabsetPanel(type = "tabs",
        tabPanel("% in low income", plotOutput("plot1"), textOutput("text")),
        tabPanel("# in low income", plotOutput("plot2")),
        tabPanel("Data summary",
                 withTags(div(class='row-fluid',
                              div(class = 'span3', selectInput("stat", "View:",
                                                             choices = c("Poverty Rate" = "Percentage of persons in low income",
                                                                         "Poverty Count (x 1,000)" = "Number of persons in low income (x 1,000)"))),
                              div(class = 'span3', selectInput("var1", "by:",
                                                               choices = c("Year", "Geography *" = "Geography", 
                                                                           "Population *" = "Population", "Line"),
                                                               selected = "Year")),
                              div(class = 'span3',selectInput("var2", "and:", 
                                                              choices = c("Year", "Geography *" = "Geography",
                                                                          "Population *" = "Population", "Line"),
                                                              selected = "Geography")),
                              div(class = 'span1', downloadButton("downloadSummary", "Download summary"))
                 )),
                 tableOutput("table"))
      )
    )
  )
))