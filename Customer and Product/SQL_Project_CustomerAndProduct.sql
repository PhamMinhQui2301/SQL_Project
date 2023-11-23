select top 5*
from [dbo].[customers]

select top 5*
from[dbo].[employees]

select top 5*
from[dbo].[offices]

select top 5*
from[dbo].[orderdetails]

select top 5*
from[dbo].[offices]

select top 5*
from[dbo].[orders]

select top 5*
from[dbo].[payments]

select top 5*
from[dbo].[productlines]

select top 5*
from[dbo].[products]



-- ###############################################################

-- ** Vấn đề: Đối với một nhà phân phối sản phẩm việc xác định các sản phẩm nào của bên mình bán chạy và tồn kho nhiều 
--            là bài toán rất quan trọng.  Nó đề cập đến các báo cáo hàng tồn kho, bao gồm lượng hàng sắp hết và hiệu suất sản phẩm
--            Điều này sẽ tối ưu hóa nguồn cung và trải nghiệm người dùng bằng cách ngăn các sản phẩm bán chạy nhất hết hàng.



-- Thứ nhất:  Lượng hàng tồn kho thấp thể hiện số lượng tổng của từng sản phẩm được đặt hàng chia cho số lượng sản phẩm trong kho.
--           Chúng ta có thể xem xét mười tỷ lệ cao nhất. Đây sẽ là top 10 sản phẩm gần như hết hàng hoặc hết hàng hoàn toàn.
                                            
--											 Low stock
SELECT top 10 productCode,
	   ROUND(Sum(quantityOrdered)*1.0 / (select [quantityInStock] from products as p where od.productCode = p.productCode),2) as low_Stock
from orderdetails as od
group by productCode
order by low_stock DESC;



-- Thứ hai: Hiệu suất sản phẩm thể hiện tổng doanh thu trên mỗi sản phẩm.
--                  Product performance
SELECT top 10 productCode,
SUM(quantityOrdered * priceEach) AS prodPerf
FROM orderdetails od
GROUP BY productCode
ORDER BY prodPerf DESC


-- Thứ ba: Các sản phẩm ưu tiên nhập kho là những sản phẩm có hiệu suất sản phẩm cao đang trên đà hết hàng 
--                         Priority products for restocking

with
low_stock_table as (
SELECT top 10 productCode,
	   ROUND(Sum(quantityOrdered)*1.0 / (select [quantityInStock] from products as p where od.productCode = p.productCode),2) as low_Stock
from orderdetails as od
group by productCode
order by low_stock DESC
)
select top 10 productCode, 
		sum(quantityOrdered * priceEach) As prod_perf
from orderdetails as od
where productCode IN (select productCode from low_stock_table)
group by productCode
order By prod_perf DESC

-- ##########################################
-- Vấn đề: Phân loại khách hàng là một phần quan trọng trong chiến lược kinh doanh của một doanh nghiệp. 
--         Việc phân chia khách hàng thành các nhóm khác nhau như khách hàng VIP và khách hàng ít tương tác 
--         giúp tạo ra nhiều lợi ích quan trọng cho doanh nghiệp. Vậy chúng ta phân loại khách hàng trên như thế nào? 

-- Thứ nhất: Truy vấn  để có thông tin khách hàng và sản phẩm ở cùng một nơi. Chọn những khách hàng, tính toán lợi nhuận khách hàng.
--                           Revenue by Customer
SELECT
  o.customerNumber,
  SUM(quantityOrdered * (priceEach + buyPrice)) AS revenue
FROM
  products p
INNER JOIN
  orderdetails od ON p.productCode = od.productCode
INNER JOIN
  orders o ON o.orderNumber = od.orderNumber
GROUP BY
  o.customerNumber;

-- Tìm năm khách hàng VIP hàng đầu.
WITH
  money_in_by_customer_table AS (
    SELECT
      o.customerNumber,
      SUM(quantityOrdered * (priceEach + buyPrice)) AS revenue
    FROM
      products as p
    INNER JOIN orderdetails as od ON p.productCode = od.productCode

    INNER JOIN orders as o ON o.orderNumber = od.orderNumber
    GROUP BY
      o.customerNumber
)		
SELECT top 5
  contactLastName,
  contactFirstName,
  city,
  country,
  mc.revenue
FROM
  customers as c
INNER JOIN money_in_by_customer_table mc ON mc.customerNumber = c.customerNumber
ORDER BY mc.revenue DESC


-- Tương tự nhóm khách hàng VIP truy vấn để tìm ra năm khách hàng ít tương tác nhất. 
WITH
  less_engaging_customers AS (
    SELECT
      o.customerNumber,
      SUM(quantityOrdered * (priceEach + buyPrice)) AS revenue
    FROM
      products as p
    INNER JOIN orderdetails od ON p.productCode = od.productCode
    INNER JOIN
      orders as o ON o.orderNumber = od.orderNumber
    GROUP BY o.customerNumber
)
SELECT top 5
  contactLastName,
  contactFirstName,
  city,
  country,
  mc.revenue
FROM
  customers c
INNER JOIN
  less_engaging_customers mc ON mc.customerNumber = c.customerNumber
ORDER BY
  mc.revenue





