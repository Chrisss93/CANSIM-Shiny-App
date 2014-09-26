library(shiny)
if(!"ShinyIncubator" %in% installed.packages()[,"Package"]) {
  install_github("shiny-incubator", "rstudio")
}

shinyUI(
  navbarPage("CANSM 202-0802 Interactive Visualization",
         tabPanel("Plots",
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
                      sliderInput("range", "Select years to review:" , min = 1976, max = 2011, value = c(1976, 2011),format = 0),
                      downloadButton("downloadRaw", "Download data"),
                      helpText("* Note: For simplicity, the Population parameter only captures age and gender categories.
               For similar reasons, the Geography parameter only captures provincial identifiers.")), 
                    mainPanel(
                      shinyIncubator::progressInit(),
                      tabsetPanel(
                        tabPanel("% in low income", plotOutput("plot1")),
                        tabPanel("# in low income", plotOutput("plot2")))))),
         tabPanel("Data summary",
                  fluidRow(
                    column(3, selectInput("stat", "View:",
                                          choices = c("Poverty Rate" = "Percentage of persons in low income",
                                                      "Poverty Count (x 1,000)" = "Number of persons in low income (x 1,000)"))),
                    column(3, selectInput("var1", "by:",
                                          choices = c("Year", "Geography *" = "Geography", 
                                                      "Population *" = "Population", "Line"),
                                          selected = "Year")),
                    column(3, selectInput("var2", "and:", 
                                          choices = c("Year", "Geography *" = "Geography",
                                                      "Population *" = "Population", "Line"),
                                          selected = "Geography")),
                    column(3, downloadButton("downloadSummary", "Download summary"))),
                  conditionalPanel(condition = "input.var1 !== input.var2",
                                   tableOutput("table")),
                  conditionalPanel(condition = "input.var1 == input.var2",
                                   p("Two different variables must be selected.", style = "color:red"))),
         tabPanel("About", h1("About CANSIM"),
                  p("CANSIM is Statistics Canada's key socioeconomic database. Updated daily, 
            CANSIM provides fast and easy access to a large range of the latest statistics 
           available in Canada."),
                  h4("Low Income Lines"),
                  p(strong("LICO"), ": After-tax low income cut-offs (1992 base) were 
                    determined from an analysis of the 1992 Family Expenditure Survey 
                    data. These income limits were selected on the basis that families 
                    with incomes below these limits usually spent 63.6% or more of 
                    their income on food, shelter and clothing. Low income cut-offs 
                    were differentiated by community size of residence and family size."),
                  p(strong("LIM"), ": Low income measures (LIMs), are relative measures 
                    of low income, set at 50% of adjusted median household income. 
                    These measures are categorized according to the number of persons 
                    present in the household, reflecting the economies of scale 
                    inherent in household size."),
                  p(strong("MBM"), ": The Market Basket Measure (MBM) attempts to measure 
                    a standard of living that is a compromise between subsistence and 
                    social inclusion. It also reflects differences in living costs across 
                    regions. The MBM represents the cost of a basket that includes: a 
                    nutritious diet, clothing and footwear, shelter, transportation, and 
                    other necessary goods and services (such as personal care items or 
                    household supplies). The cost of the basket is compared to disposable 
                    income for each family to determine low income rates. Following a review 
                    by Human Resources and Skills Development Canada, the shelter component of 
                    the MBM thresholds along with the disposable income definition have been 
                    revised. The revision takes effect in 2011 and includes an historical 
                    revision back to 2002 (the first year in which housing tenure information 
                    is available in SLID). See Statistics Canada Income Research Paper (75F0002M) 
                    Low Income Lines, 2011-2012 for details."),
                  
                  a("Click here to access the data", 
                    href = "http://www5.statcan.gc.ca/cansim/a26?lang=eng&retrLang=eng&id=2020802&paSer=&pattern=&stByVal=1&p1=1&p2=-1&tabMode=dataTable&csid="),
                  br(),
                  em("Source:  Statistics Canada. Table  202-0802 -  Persons in low income families, annual,  CANSIM
                         (database). accessed:"), span(Sys.Date(),style = "color:blue"),
                  br(), br(),
                  em("CANSIM is a registered trademark of Statistics Canada and is an official mark adopted and used 
                         by Her Majesty the Queen in Right of Canada as represented by the Minister of Industry Canada."), br(), br(),
                  img(src = "http://www.statcan.gc.ca/wet-boew/dist/theme-gcwu-fegc/images/wmms-alt.png", 
                      width="134", height="32",align = "right")
         )
  )
)