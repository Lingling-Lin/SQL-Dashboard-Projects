import pandas as pd
import plotly.express as px
import streamlit as st

# st.set_page_config(page_title = 'Sales Dashboard',
#                     page_icon = ':bar_chart:',
#                     layout = 'wide')

st.set_page_config(page_title="Sales Dashboard", page_icon=":bar_chart:", layout="wide")

# TO AVOID READ DF AGAIN AND AGAIN WHEN FRESH THIS FILE
# we will get the information from short term memory
@st.cache_data
def get_data_from_excel():
    df = pd.read_excel(
        io = 'supermarkt_sales.xlsx',
        engine='openpyxl',
        sheet_name='Sales',
        skiprows=3,
        usecols= 'B:R',
        nrows=1000
    )

# ADD 'HOUR' column to dataframe
    df['Hour'] = pd.to_datetime(df['Time'], format = '%H:%M:%S').dt.hour
    return df
df = get_data_from_excel()

# --- SIDEBAR ----
st.sidebar.header("Please Filter Here: ")
city = st.sidebar.multiselect(
    "Select the City",
    options = df['City'].unique(),
    default = df['City'].unique()
)

customer_type = st.sidebar.multiselect(
    "Select the Customer Type",
    options = df['Customer_type'].unique(),
    default = df['Customer_type'].unique()
)

gender = st.sidebar.multiselect(
    "Select the Gender",
    options = df['Gender'].unique(),
    default = df['Gender'].unique()
)

df_selection = df.query(
    "City == @city & Customer_type == @customer_type & Gender == @gender"
)


#--- MAINPAGE ---
st.title(":bar_chart: Sales Dashboard")
st.markdown('##') # insert a new paragraph using a markdown field

# --- TOP KPIs --- (total sales, the average rating and the average sales by a transaction)
total_sales = int(df_selection['Total'].sum())
avg_rating = round(df_selection['Rating'].mean(),1)
star_rating = ":star:" * int(round(avg_rating,0))  # rating score by emojis
average_sale_by_transaction = round(df_selection['Total'].mean(),2)

left_column, middle_column, right_column = st.columns(3)
with left_column:
    st.subheader("Total Sales:")
    st.subheader(f"US $ {total_sales:,}")

with middle_column:
    st.subheader('Average Rating:')
    st.subheader(f"{avg_rating} {star_rating}")

with right_column:
    st.subheader('Average Sales Per Transaction:')
    st.subheader(f"US $ {average_sale_by_transaction}")

st.markdown("---") # insert a divider 

# SALES BY PRODUCT LINE [BAR CHART]
sales_by_product_line = (
    df_selection.groupby('Product line')[['Total']].sum().sort_values(by = 'Total')
)

fig_product_sales = px.bar(
    sales_by_product_line,
    x= 'Total',
    y = sales_by_product_line.index, #product line
    orientation = 'h',
    title = "<b>Sales by Product Line </b>", # bold text
    color_discrete_sequence = ['#0083B8'] * len(sales_by_product_line),
    template = 'plotly_white',
)

# remove grid from plot (already be default setting in our version of streamlit)
fig_product_sales.update_layout(
    plot_bgcolor = 'rgba(0,0,0,0)',
    xaxis = (dict(showgrid = False))
)


# SALES BY HOUR [BAR CHART]
sales_by_hour = df_selection.groupby('Hour')[['Total']].sum()

fig_hourly_sales = px.bar(
    sales_by_hour,
    x= sales_by_hour.index,
    y = "Total", #product line
    title = "<b>Sales by hour </b>", # bold text
    color_discrete_sequence = ['#0083B8'] * len(sales_by_hour),
    template = 'plotly_white',
)

left_column, right_column = st.columns(2)
left_column.plotly_chart(fig_hourly_sales, use_container_width = True)
right_column.plotly_chart(fig_product_sales, use_container_width = True)